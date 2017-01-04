#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#config
config_dir="$HOME/.config/samba-for-user"
mkdir -p "$config_dir"

test ! -f "$config_dir/shares.config.in" && test -f "$script_dir/config/shares.config.in" && echo "copying custom shares.config.in" && cp "$script_dir/config/shares.config.in" "$config_dir/shares.config.in"
test ! -f "$config_dir/shares.config.in" && cp "$script_dir/shares.config.in" "$config_dir"

test ! -f "$config_dir/global-addons.config.in" && test -f "$script_dir/config/global-addons.config.in" && echo "copying custom global-addons.config.in" && cp "$script_dir/config/global-addons.config.in" "$config_dir/global-addons.config.in"
test ! -f "$config_dir/global-addons.config.in" && cp "$script_dir/global-addons.config.in" "$config_dir"

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/samba"
mkdir -p "$bin_dir"
cp "$script_dir/samba-start.sh" "$bin_dir"
chmod 755 "$bin_dir/samba-start.sh"
cp "$script_dir/samba-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/samba-stop.sh"
cp "$script_dir/samba-post.sh" "$bin_dir"
chmod 755 "$bin_dir/samba-post.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

thisuser=`id -u`
thisusername=`whoami`

unit="samba-for-user.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/samba-start.sh -g \"$config_dir/global-addons.config.in\" \"$config_dir/shares.config.in\"|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/samba-stop.sh|g" "/tmp/$unit"
sed -i -e "s|__dir|$bin_dir|g" "/tmp/$unit"
sed -i -e "s|__pid|/tmp/samba-service-for-$thisuser/pids/smbd.pid|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

