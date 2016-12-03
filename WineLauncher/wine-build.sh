#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
script_link=`readlink "$script_dir/$0"`
test ! -z "$script_link" && script_dir=`realpath \`dirname "$script_link"\``

profile="$1"
test -z "$profile" && echo "usage: wine-build <profile> <install prefix> [alternative wine-build.cfg.lua config file]" && exit 1

prefix="$2"
test -z "$prefix" && echo "usage: wine-build <profile> <install prefix> [alternative wine-build.cfg.lua config file]" && exit 1

config="$3"
test -z "$config" && config="$script_dir/wine-build.cfg.lua"

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e build -b "$script_dir/build.pre.lua" -a "$script_dir/build.post.lua" -o "$profile" -o "$prefix"


