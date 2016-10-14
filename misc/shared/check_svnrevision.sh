#! /bin/sh
#
# check_version.sh
# Copyright (C) 2012-2016 Bull S.A.S
#
# Distributed under terms of the BULL license.
#


if ! test -e $1/svnversion; then
    exit 0;
fi
if test -e $2/svnversion; then
    MODIF=$(git status -s | grep -v "??" | wc -l)
    if test "$MODIF" != 0; then
        ST=" MODIFIED"
    else
        ST=""
    fi
    echo $(git -C $2 symbolic-ref HEAD 2> /dev/null | cut -b 12-)-$(git -C $2 log --pretty=format:'%H, %ad' --date=iso -1) | sed 's/$/'"$ST"'/' > tmp.svnversion;
    diff $2/svnversion tmp.svnversion > /dev/null 2>&1 
    if test $? -ne 0; then
        rm $2/svnversion
    fi;
    #rm tmp.svnversion;
fi
