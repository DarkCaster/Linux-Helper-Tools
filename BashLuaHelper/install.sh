#!/bin/bash

#install bash lua helper stuff locally into the home directory

script_dir="$( cd "$( dirname "$0" )" && pwd )"

bin_dir="$@"
test -z "$bin_dir" && echo "installing to home directory: $HOME/apps/bash-lua-helper" && bin_dir="$HOME/apps/bash-lua-helper"
bin_dir=`realpath $bin_dir`

mkdir -p "$bin_dir"
cp "$script_dir/loader.lua" "$bin_dir"
cp "$script_dir/lua-helper.bash.in" "$bin_dir"

