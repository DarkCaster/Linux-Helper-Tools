#!/bin/bash

checkout="b5770a20076387cf39fd1faff2a33826e18812e2"

mkd="mktemp -d"
tmpdir="$($mkd)"

srcdirname="Archives"

curdir="$( cd "$( dirname "$0" )" && pwd )"
srcdir="$curdir/$srcdirname"

. "$srcdir"/service-funcs.sh.in

"$curdir/download.sh" "$checkout"
check_error

clean_deps
check_error

cd "$tmpdir"
check_error

####################################

. "$srcdir"/build-libvpx.sh
check_error

####################################

echo "===CLEANING UP==="

cd "$curdir"
check_error

rm -rf "$tmpdir"
check_error

echo "===SCRIPT FINISHED==="
exit 0
