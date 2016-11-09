#!/bin/bash

echo "===BUILDING libvpx==="
prepare_pkg libvpx
check_error

libvpxdir="$PWD"

mkdir "$tmpdir/libvpx_build"
check_error

cd "$tmpdir/libvpx_build"
check_error

#--enable-unit-tests
"$libvpxdir/configure" --prefix="//" --libdir="//lib" --disable-docs --disable-vp8 --enable-vp9 --enable-vp9-highbitdepth --enable-postproc --enable-vp9-postproc --enable-coefficient-range-checking --disable-pic --disable-shared --enable-static --disable-multithread --enable-multi-res-encoding --enable-vp9-temporal-denoising --enable-webm-io
check_error

make
check_error

make install DESTDIR="$tmpdir/libvpx_install"
check_error

#LIBVPX_TEST_DATA_PATH=../libvpx-test-data make testdata
#check_error

install_from "$tmpdir/libvpx_install"
check_error

clean_pkg libvpx
echo "===libvpx BUILD FINISHED==="
echo " "

