#!/bin/bash

mkd="mktemp -d"
tmpdir="$($mkd)"

srcdirname="Archives"

curdir="$( cd "$( dirname "$0" )" && pwd )"
srcdir="$curdir/$srcdirname"

. "$srcdir"/service-funcs.sh.in

clean_deps
check_error

cd "$tmpdir"
check_error

####################################

rm -rf "$curdir"/Deps
check_error

xz -c -d "$srcdir/precompiled-archive.tar.xz" | tar xvf -
check_error

mv Deps "$curdir"
check_error

####################################

echo "===CLEANING UP==="

cd "$curdir"
check_error

rm -rf "$tmpdir"
check_error

echo "===SCRIPT FINISHED==="
exit 0
