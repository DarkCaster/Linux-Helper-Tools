#!/bin/bash
#

# register hook-manager to work with libvirt - install symlinks to main qemu-hook.sh script and local directory where hook-config files will be installed

set -e

target="$1"
cfg_dir="$2"
[[ -z $target ]] && echo "usage: activate.sh <libvirt etc directory> [optional user-writable directory for hook-configs files installation]" && exit 1

script_dir="$( cd "$( dirname "$0" )" && pwd )"

mkdir -p "$target/hooks"
ln -s "$script_dir/qemu-hook.sh" "$target/hooks/qemu"
[[ ! -z "$cfg_dir" ]] && ln -s "$target/hooks/hook_manager" "$cfg_dir"
