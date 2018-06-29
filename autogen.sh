#!/bin/bash

if [ "x$EDITOR" = "x" ];
then
        EDITOR=vi
fi

if [ "x$1" = "x-f"  ]
then
    autoscan
    [ -f "configure.ac" ] && cp "configure.ac" "configure.ac.old"
    mv -f "configure.scan" "configure.ac"
    echo "## This is just AUTOSCAN draft of configure.ac"
    $EDITOR "configure.ac"
fi

### použít jen když je třeba použít configure.h.in
#autoheader

aclocal \
&& automake -a -c \
&& autoconf
