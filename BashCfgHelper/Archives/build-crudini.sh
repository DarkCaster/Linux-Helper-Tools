#!/bin/bash

echo "===BUILDING crudini==="
prepare_pkg crudini
check_error

#compile
mv crudini crudini.py
check_error

python -m compileall crudini.py
check_error

#test
python crudini.pyc --get example.ini DEFAULT global 2>/dev/null 1>&2
check_error

install_file "crudini.pyc" bin
check_error

clean_pkg crudini
echo "===crudini BUILD FINISHED==="
echo " "

