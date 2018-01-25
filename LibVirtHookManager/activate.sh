#!/bin/bash
#

# register hook-manager to work with libvirt - install symlinks to main qemu-hook.sh script and local directory where hook-config files will be installed

set -e

target="$1"
cfg_dir="$2"
[[ -z $target ]] && echo "usage: activate.sh <libvirt etc directory> [optional user-writable directory for hook-configs files installation]" && exit 1

script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $script_dir/$self ]] && echo "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $script_dir/$self ]]; then
  script_file=`readlink -f "$script_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
fi

mkdir -p "$target/hooks"
ln -s "$script_dir/qemu-hook.sh" "$target/hooks/qemu"
[[ ! -z "$cfg_dir" ]] && ln -s "$target/hooks/hook_manager" "$cfg_dir"
[[ -z "$cfg_dir" ]] && cfg_dir="$target/hooks"

# write config dir location
2>/dev/null echo "$cfg_dir" > "/etc/qemu-hook-cfgdir" && exit 0 || true
2>/dev/null echo "$cfg_dir" > "$script_dir/qemu-hook-cfgdir" && exit 0 || true
