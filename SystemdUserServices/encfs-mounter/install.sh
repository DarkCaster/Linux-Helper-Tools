#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#config
config_dir="$HOME/.config/encfs-mounter"
mkdir -p "$config_dir"

test ! -f "$config_dir/mounts.cfg" && test -f "$script_dir/config/mounts.cfg" && echo "copying custom mounts.cfg" && cp "$script_dir/config/mounts.cfg" "$config_dir/mounts.cfg"
test ! -f "$config_dir/mounts.cfg" && cp "$script_dir/mounts.cfg" "$config_dir"

#binaries
bin_dir="$HOME/bin"
mkdir -p "$bin_dir"
cp "$script_dir/enc-mount.sh" "$bin_dir"
chmod 755 "$bin_dir/enc-mount.sh"
cp "$script_dir/enc-umount.sh" "$bin_dir"
chmod 755 "$bin_dir/enc-umount.sh"

#auto-mounter-scripts
bin_dir="$HOME/apps/systemd-services/encfs-auto-mounter"
mkdir -p "$bin_dir"
cp "$script_dir/auto-start.sh" "$bin_dir"
chmod 755 "$bin_dir/auto-start.sh"
cp "$script_dir/auto-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/auto-stop.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="encfs-auto-mounter.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/auto-start.sh|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/auto-stop.sh|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

