#!/bin/sh

# Update doxygen conf file to use tagfiles from other doxygen projects
#
# @AUTHOR John Gliksberg 2016,2017
#
# Usage
# =====
#
#     ./gen_doxydeps.sh DOXYCONF \
#         PATH/TO/TAGFILE1=FUTURE/PATH/TO/DOC1 \
#         [ PATH/TO/TAGFILE2=FUTURE/PATH/TO/DOC2 ... ]
#
# Example
# =======
#
#  base/
# |_ module1/                   # Project (dependency) to be referenced
# | |_ packaged/
# | | |_ doc/
# | |   |_ Doxygen_specific.in  # Contains GENERATE_TAGFILE=doxygen.tags
# | |_ build/
# |   |_ packaged/
# |     |_ doc/
# |       |_ doxygen.tag        # TAGFILE that must be made available
# |       |                     # to doxygen
# |       |_ html/              # DEPHTML which is the root of the
# |         |                   # dependency's output doc
# |         |_ ...
# |_ module2/                   # Current project
#   |_ packaged/
#   | |_ doc/
#   |   |_ Doxygen_specific.in  # What we want to update
#   |_ gen_doxydeps.sh          # This script
#
# To update module2/packaged/doc/Doxygen_specific.in to know where module1's
# TAGFILE is, you would run
#
#     ./gen_doxydeps.sh packaged/doc/Doxygen_specific.in \
#         "../module1/build/packaged/doc/doxygen.tag \
#         =../../../../module1/build/packaged/doc/html"
#
# or maybe from base/,
#
#     module2/gen_doxygen.sh module2/packaged/doc/Doxygen_specific.in \
#         "module1/build/packaged/doc/doxygen.tag \
#         =../../../../module1/build/packaged/doc/html"

# Check number of arguments
if test "$#" -lt 2
then
    # Output help and exit before breaking stuff
    printf "Usage: gen_doxydeps.sh DOXYCONF "
    printf "PATH/TO/TAGFILE1 [ PATH/TO/TAGFILE2 ... ]\n\n"
    test -n "$1" && touch $1
    exit
fi

DOXYCONF="$1" #packaged/doc/Doxygen_specific.in
DOXYDIR="$(dirname "$DOXYCONF")"
shift # Pop first argument

# Create Doxyfile with TAGFILES lines
if test -e "$DOXYCONF"
then
    echo "$DOXYCONF already exists; deleting it."
    rm "$DOXYCONF"
fi
for ARG in "$@"
do
    TAGFILE="$(echo "$ARG" | sed 's/[ \t]*=[^=]*$//')"
    HTMLDIR="$(echo "$ARG" | sed 's/^[^=]*=[ \t]*//')"
    # If TAGFILE is relative, compute it relative to DOXYDIR
    if ! echo "$TAGFILE" | grep -q "^/"
    then
        TAGFILE="$(realpath --no-symlink \
                            --relative-to="$DOXYDIR" \
                            "$TAGFILE")"
    fi
    # Remove duplicate slashes, but don't interpret / canonicalize
    HTMLDIR="$(echo "$HTMLDIR" | sed "s#//\+#/#g")"
    # Compute path to dep's doc output, relative to current doc output
    echo "TAGFILES += \"$TAGFILE \\" >> "$DOXYCONF"
    echo "            =$HTMLDIR\""   >> "$DOXYCONF"
done
