#!/bin/bash

checkout="f5141ea45fee014b529a264c1fa3bdedd42d038c"

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