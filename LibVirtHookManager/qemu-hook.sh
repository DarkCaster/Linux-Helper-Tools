#!/bin/bash

obj="$1"
op="$2"
sub="$3"

# silently exit on unsupported operations
[[ $op = attach || $op = reconnect || $op = restore || $op = migrate ]] && exit 0

logfile=""

debug () {
  echo "[QEMU-HOOK] $@"
  [[ ! -z $logfile ]] && echo "[QEMU-HOOK] $@" >> "$logfile"
  true
}

while read line
do
  [[ $line =~ "<uuid>"([0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+)"</uuid>" ]] && \
    uuid=`echo ${BASH_REMATCH[1]} | tr '[:upper:]' '[:lower:]'` && break
done < "${4:-/dev/stdin}"

[[ -z $uuid ]] && debug "no valid domain UUID was decoded from provided XML file" && exit 0

debug "working with $uuid"

#detection of actual script location, and\or link location
link_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $link_dir/$self ]] && debug "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $link_dir/$self ]]; then
  script_file=`readlink -f "$link_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
else
  script_dir="$link_dir"
fi

#detect hooks_dir
hooks_dir="$link_dir"
[[ -d "$link_dir/hook_manager" ]] && hooks_dir="$link_dir/hook_manager"

#try hook-config
hook_cfg="$link_dir/$uuid.cfg.lua"
[[ ! -L $hook_cfg ]] && debug "hook-config for uuid=$uuid is not installed, exiting" && exit 0
hook_cfg=`readlink "$hook_cfg"`
[[ ! -e $hook_cfg ]] && debug "hook-config for uuid=$uuid is a dangling symlink, exiting" && exit 0
hook_cfg_uid=`realpath -s "$hook_cfg" | md5sum -t | cut -f1 -d" "`

tmp_dir="$TMPDIR"
[[ -z $tmp_dir || ! -d $tmp_dir ]] && tmp_dir="/tmp"
tmp_dir=`realpath -m "$tmp_dir/qemu-hooks-$hook_cfg_uid"`
mkdir -p "$tmp_dir" || exit 10
logfile="$tmp_dir/debug.log"

. "$script_dir/find-lua-helper.bash.in" "$script_dir/BashLuaHelper" "$script_dir/../BashLuaHelper"

. "$bash_lua_helper" "$hook_cfg" -e hooks -b "$script_dir/hook-config.pre.lua" -a "$script_dir/hook-config.post.lua" -o "$uuid" -o "$hook_cfg_uid" -o "$script_dir" -o "$tmp_dir"

[[ "${#cfg[@]}" = 0 ]] && debug "can't find config storage variable populated by bash_lua_helper. bash_lua_helper failed!" && exit 1
