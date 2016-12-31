#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#config
config_dir="$HOME/.config/dnsmasq-for-user"
mkdir -p "$config_dir"

test ! -f "$config_dir/dnsmasq.conf.in" && test -f "$script_dir/config/dnsmasq.conf.in" && echo "copying custom dnsmasq.conf.in" && cp "$script_dir/config/dnsmasq.conf.in" "$config_dir/dnsmasq.conf.in"
test ! -f "$config_dir/dnsmasq.conf.in" && cp "$script_dir/dnsmasq.conf.in" "$config_dir"

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/dnsmasq"
mkdir -p "$bin_dir"
cp "$script_dir/dmsq-start.sh" "$bin_dir"
chmod 755 "$bin_dir/dmsq-start.sh"
cp "$script_dir/dmsq-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/dmsq-stop.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="dnsmasq-for-user.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/dmsq-start.sh \"$config_dir/dnsmasq.conf.in\"|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/dmsq-stop.sh|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

