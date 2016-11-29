#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

#build crudini
"$script_dir/build.sh"
if [ "$?" != "0" ]; then
exit 1
fi

#feature scripts
bin_dir="$HOME/apps/bash-cfg-helper"
mkdir -p "$bin_dir"
cp "$script_dir/cfg-helper.sh.in" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/cfg-helper.sh.in"
chmod 644 "$bin_dir/cfg-helper.sh.in"
cp "$script_dir/Deps/bin/crudini.pyc" "$bin_dir"

