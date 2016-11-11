#!/bin/bash

link="https://github.com/dubhater/vapoursynth-nnedi3/raw/master/src/nnedi3_weights.bin"

srcdirname="Archives"
curdir="$( cd "$( dirname "$0" )" && pwd )"
srcdir="$curdir/$srcdirname"

cd "$srcdir"

test -f "nnedi3_weights.bin" && exit 0

wget $link

