#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
script_link=`readlink "$script_dir/$0"`
test ! -z "$script_link" && script_dir=`realpath \`dirname "$script_link"\``

config="$1"
test -z "$config" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

profile="$1"
test -z "$profile" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

params="$@"
params_key="-o"
test -z "$params" && params_key=""

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e profile -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" $params_key "$params"
