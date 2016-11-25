#!/bin/sh

# Update doxygen conf file to use tagfiles from other doxygen projects
#
# This is probably going to be called by the rpm building mechanism
#
# @AUTHOR John Gliksberg 2016
#
# Usage
# =====
#
#     ./gen_doxydeps.sh DOXYCONF PATH/TO/TAGFILE1 [ PATH/TO/TAGFILE2 ... ]
#
# Assumptions
# ===========
#
# - The html output directory from the dependency doxygen
#   is in the same directory as it's output TAGFILE
# - It's called html
# - The html output directory for the current doxygen
#   will be in the same directory as the current DOXYCONF
#   EVEN AFTER INSTALLATION
#   @TODO CHECK / FIX @SEEALSO HTMLDIR COMPUTATION IN THIS SCRIPT
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
# |       |_ doxygen.tag        # TAGFILE that must be made available to doxygen
# |       |_ html/              # DEPHTML which is the root of the dependency's output doc
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
#                       ../module1/build/packaged/doc/doxygen.tag
#
# or maybe from base/,
#
#     module2/gen_doxygen.sh module2/packaged/doc/Doxygen_specific.in \
#                            module1/build/packaged/doc/doxygen.tag
#
# @TODO: show example with absolute path

# Check number of arguments
if test "$#" -lt 2
then
    # Output help and exit before breaking stuff
    printf "Usage: gen_doxydeps.sh DOXYCONF "
    printf "PATH/TO/TAGFILE1 [ PATH/TO/TAGFILE2 ... ]\n\n"
    if test $1
    then
        touch $1
    fi
    exit
fi

DOXYCONF=$1 #packaged/doc/Doxygen_specific.in
# @TODO: Resolve symlink ?
DOXYDIR="$(dirname "$DOXYCONF")"
shift # Pop first argument
ARGS=("$@")

# When we were modifying the existing Doxyfile_specific
# it made sense to strip it first
# Instead we choose to create a new Doxyfile_specific_tagfiles
# # Strip existing TAGFILES lines from doxygen conf file.
# # No backup, be careful :-)
# sed -i '
#     /^TAGFILES[ \t]*+\?=/ {  # For each TAGFILES line
#         :again               #   Loop begin
#         /\\$/ {              #     If line ends with a backslash
#             N                #     Extend pattern space to next line
#             t again          #   Loop end
#         }
#         d                    #   Delete pattern space
#     }
# ' $DOXYCONF

# Create Doxyfile with TAGFILES lines
if test -e "$DOXYCONF"
then
    echo "$DOXYCONF already exists; deleting it."
    rm "$DOXYCONF"
fi
#rm -f $DOXYCONF
for ARG in "${ARGS[@]}"
do
    # @TODO: Resolve symlinks ?
    TAGFILE="$(echo "$ARG" | sed 's/[ \t]*=[^=]*$//')"
    HTMLDIR="$(echo "$ARG" | sed 's/^[^=]*=[ \t]*//')"
    # If TAGFILE is relative, compute it relative to DOXYDIR
    echo "$TAGFILE" | grep -o "^." | grep -q "/" || \
        TAGFILE="$(realpath --relative-to="$DOXYDIR" "$TAGFILE")"
    # @TODO: CHECK WHETHER IT WORKS ONCE RPM IS INSTALLED
    #        @SEEALSO THIS SCRIPT'S TOP DOC
    #        MAYBE USE --relative-to=SERVER-ROOT-PATH
    # If HTMLDIR is relative, compute it relative to DOXYDIR/html
    echo "$HTMLDIR" | grep -o "^." | grep -q "/" || \
        HTMLDIR="$(realpath --relative-to="$DOXYDIR/html/" "$HTMLDIR")"
    # Compute path to dep's doc output, relative to current doc output
    echo "TAGFILES += \"$TAGFILE \\" >> "$DOXYCONF"
    echo "           = $HTMLDIR\""   >> "$DOXYCONF"
done
