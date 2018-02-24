#!/bin/bash

#detection of actual script location
curdir="$PWD"
script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $script_dir/$self ]] && echo "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $script_dir/$self ]]; then
  script_file=`readlink -f "$script_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
fi

#load parameters
config="$1"
[[ -z $config ]] && echo "usage: libvirt-launcher.sh <config file> <profile> [extra parameters]" && exit 1
shift 1
profile="$1"
[[ -z $profile ]] && echo "usage: libvirt-launcher.sh <config file> <profile> [extra parameters]" && exit 1
shift 1

debug_enabled="false"

debug () {
  [[ $debug_enabled == false ]] && return 0
  local mark=`date "+%Y-%m-%d %H:%M:%S"`
  1>&2 echo "[DEBUG] $@"
  [[ ! -z $logfile ]] && echo "[$mark] $@" >> "$logfile"
  return 0
}

#activate some laodables if available
. "$script_dir/loadables-helper.bash.in"
#check for some required commands
. "$script_dir/find-commands.bash.in"

#generate uid for given config file
[[ ! -e $config ]] && echo "config file not found: $config" && exit 1
config_uid=`realpath -s "$config" | md5sum -t | cut -f1 -d" "`

#temp directory
tmp_dir="$TMPDIR"
[[ -z $tmp_dir || ! -d $tmp_dir ]] && tmp_dir="/tmp"

. "$script_dir/find-lua-helper.bash.in" "$script_dir/BashLuaHelper" "$script_dir/../BashLuaHelper"

. "$bash_lua_helper" "$config" -e global_params -e actions -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -o "$HOME" -o "$script_dir" -o "$curdir" -o "$config_uid" -o "$tmp_dir" -o "$tmp_dir/libvirt-launcher-$config_uid" -x "$@"
