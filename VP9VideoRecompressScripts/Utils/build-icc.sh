#!/bin/bash

checkout="fed52670a24dee745c1ef38304938d9e5d7ecf25"

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

. "$srcdir"/build-libvpx-icc.sh
check_error

####################################

echo "===CLEANING UP==="

cd "$curdir"
check_error

rm -rf "$tmpdir"
check_error

echo "===CREATING ARCHIVE==="

rm -f "$srcdir/precompiled-archive.tar"
rm -f "$srcdir/precompiled-archive.tar.xz"
tar cf "$srcdir/precompiled-archive.tar" Deps
xz -9e "$srcdir/precompiled-archive.tar"

echo "===SCRIPT FINISHED==="
exit 0
