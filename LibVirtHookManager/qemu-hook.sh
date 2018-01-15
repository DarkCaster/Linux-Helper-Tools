#!/bin/bash

obj="$1"
op="$2"
sub="$3"

# silently exit on unsupported operations
[[ $op = attach || $op = reconnect || $op = restore || $op = migrate ]] && exit 0

debug () {
  echo "[QEMU-HOOK] $@"
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

[[ ! -e $hook_cfg ]] && debug "hook-config for uuid=$uuid is not installed, exiting" && exit 0
