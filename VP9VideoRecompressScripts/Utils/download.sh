#!/bin/bash

checkout="$1"
test -z "$checkout" && checkout="master"

srcdirname="Archives"
curdir="$( cd "$( dirname "$0" )" && pwd )"
srcdir="$curdir/$srcdirname"
cd "$srcdir"
test "$checkout" != "master" && test -f libvpx-git-$checkout.tar.xz && exit 0

rm -rf libvpx-git-*
git clone https://github.com/webmproject/libvpx.git "libvpx-git-$checkout"
cd "libvpx-git-$checkout"
git checkout $checkout
git submodule update --init
rm -rf .git
cd "$srcdir"
tar cf libvpx-git-$checkout.tar libvpx-git-$checkout --owner=0 --group=0
xz -9e libvpx-git-$checkout.tar
rm -rf libvpx-git-$checkout

