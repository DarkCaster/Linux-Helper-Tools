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

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e prefix -e profile -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -x "$@"

log () {
 echo "[ $@ ]"
}

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  log "ERROR: last operation finished with error code $status"
  exit $status
 fi
}

# echo "$cfg_list"

#external wine distribution
if check_lua_export prefix.wine; then
 winedist="${cfg[prefix.wine]}"
 test ! -d "$winedist" && log "directory $winedist is missing" && exit 1
 winedist=`realpath "$winedist"`
 test ! -d "$winedist" && log "directory $winedist is missing" && exit 1
 export WINESERVER="$winedist/bin/wineserver"
 export WINELOADER="$winedist/bin/wine"
 export LD_LIBRARY_PATH="$winedist/lib64:$LD_LIBRARY_PATH"
 export PATH="$winedist/bin:$PATH"
fi

if [ ! -d "${cfg[prefix.root]}" ]; then
 log "creating ${cfg[prefix.root]} root dir for wine prefix"
 mkdir -p "$wineroot"
 check_errors
fi

wineroot=`realpath "${cfg[prefix.root]}"`
test ! -d "$wineroot" && log "failed to transform ${cfg[prefix.root]} dir with realpath" && exit 1
export WINEPREFIX="$wineroot"


