#!/bin/bash

# Install libvirt hook manager to local user home directory
# You must run libvirt-hook-manager-activate after installation,
# in order to install symlink to qemu-hook.sh into libvirt config dir
# and register hook-config directory.
# This directory will be used for user hook-config files activation,
# and it must have write permissions for user that will run libvirt-hook-manager

target="$1"
[[ -z $target ]] && target="$HOME/libvirt_hook_manager"
[[ $target = $HOME ]] && echo "will not proceed install to home directory directly, try $HOME/libvirt_hook_manager sub-directory instead" && exit 1

curdir="$( cd "$( dirname "$0" )" && pwd )"

set -e

#install bash-lua-helper
"$curdir/../BashLuaHelper/install.sh" "$target/BashLuaHelper"

mkdir -p "$target"
cp "$curdir"/*{.sh,.lua,.in} "$target"

rm -f "$HOME/bin/libvirt-hook-manager"
rm -f "$HOME/bin/libvirt-hook-manager-activate"

ln -s "$target/libvirt-hook-manager.sh" "$HOME/bin/libvirt-hook-manager"
ln -s "$target/activate.sh" "$HOME/bin/libvirt-hook-manager-activate"
