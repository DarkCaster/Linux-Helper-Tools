#!/bin/bash

echo "===BUILDING unfs3==="
prepare_pkg unfs3
check_error

autoreconf -fiv
check_error

./configure --prefix="//" --libdir="//lib"
check_error

make
check_error

make install DESTDIR="$tmpdir/unfs3_install"
check_error

install_from "$tmpdir/unfs3_install"
check_error

clean_pkg unfs3
echo "===unfs3 BUILD FINISHED==="
echo " "

