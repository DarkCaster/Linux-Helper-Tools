#!/bin/bash

checkout="$1"
test -z "$checkout" && checkout="master"

srcdirname="Archives"
curdir="$( cd "$( dirname "$0" )" && pwd )"
srcdir="$curdir/$srcdirname"
cd "$srcdir"
test "$checkout" != "master" && test -f crudini-git-$checkout.tar.xz && exit 0

rm -rf crudini-git-*
git clone https://github.com/pixelb/crudini.git "crudini-git-$checkout"
cd "crudini-git-$checkout"
git checkout $checkout
git submodule update --init
rm -rf .git
cd "$srcdir"
tar cf crudini-git-$checkout.tar crudini-git-$checkout --owner=0 --group=0
xz -9e crudini-git-$checkout.tar
rm -rf crudini-git-$checkout

