#!/bin/bash

checkout="0ffbb36ddc5a1be8ee38ab3bdc663fd5ea99da78"

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
