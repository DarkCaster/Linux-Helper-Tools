#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/netjack-sound-server"
mkdir -p "$bin_dir"

cp "$script_dir/alsaout-start.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/alsaout-start.sh"
chmod 755 "$bin_dir/alsaout-start.sh"

cp "$script_dir/alsaout-stop.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/alsaout-stop.sh"
chmod 755 "$bin_dir/alsaout-stop.sh"

cp "$script_dir/netjack-start.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/netjack-start.sh"
chmod 755 "$bin_dir/netjack-start.sh"

cp "$script_dir/netjack-stop.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/netjack-stop.sh"
chmod 755 "$bin_dir/netjack-stop.sh"

cp "$script_dir/all-start.sh" "$bin_dir"
chmod 755 "$bin_dir/all-start.sh"

cp "$script_dir/all-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/all-stop.sh"

cp "$script_dir/service-funcs" "$bin_dir"
cp "$script_dir/alsaout-config" "$bin_dir"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="netjack-sound-server.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/all-start.sh|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/all-stop.sh|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

