#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

bin_dir="$@"

test -z "$bin_dir" && echo "installing to home directory, by default" && bin_dir="$HOME/apps/bash-cfg-helper"

bin_dir=`realpath $bin_dir`

#build crudini
if [ ! -d "$script_dir/Deps" ]; then
 "$script_dir/build.sh"
 if [ "$?" != "0" ]; then
  exit 1
 fi
fi

#feature scripts
mkdir -p "$bin_dir"
cp "$script_dir/Src/cfg-helper.sh.in" "$bin_dir"
sed -i -e "s|__CFGHELPER|$bin_dir|g" "$bin_dir/cfg-helper.sh.in"
chmod 644 "$bin_dir/cfg-helper.sh.in"
cp "$script_dir/Deps/bin/crudini.pyc" "$bin_dir"

