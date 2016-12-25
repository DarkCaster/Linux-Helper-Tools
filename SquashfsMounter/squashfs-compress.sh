#!/bin/bash

srcdir="$1"
target="$2"
fast="$3"

test "z$fast" != "zyes" && fast="no"

olddir="$PWD"

test "z$srcdir" = "z" -o "z$target" = "z" && echo "srcdir or target is not set" && exit 1

target="$olddir/$target.sfs"

echo "srcdir = $srcdir"
echo "target = $target"
echo "fast = $fast"

test ! -d "$srcdir" && echo "srcdir is not exist!" && exit 1
test -f "$target" && echo "target archive already exist!" && exit 1

if [ "z$fast" = "zyes" ]; then
	echo "using compression mode without any bcj filters"
	mksquashfs "$srcdir" "$target" -comp xz -b 1M -no-xattrs -no-exports -all-root -Xdict-size 100% -mem 8G
	test "$?" != "0" && echo "last operation failed!" && exit 1
else
	echo "using compression mode WITH bcj filters"
	mksquashfs "$srcdir" "$target" -comp xz -b 1M -no-xattrs -no-exports -all-root -Xdict-size 100% -Xbcj x86,arm,armthumb,powerpc,sparc,ia64 -mem 8G
	test "$?" != "0" && echo "last operation failed!" && exit 1
fi

