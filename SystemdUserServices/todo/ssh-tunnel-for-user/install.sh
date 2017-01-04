#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

#install systemd-user-service-starter
"$script_dir/../systemd-user-service-starter/install.sh"
if [ "$?" != "0" ]; then
echo "error"
exit 1
fi

#install cfg helper
"$script_dir/../bash-cfg-helper/install.sh"
if [ "$?" != "0" ]; then
echo "error"
exit 1
fi

#config
config_dir="$HOME/.config/ssh-tunnel-for-user"
mkdir -p "$config_dir"
test ! -f "$config_dir/config.ini" && cp "$script_dir/config.ini.example" "$config_dir"

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/ssh-tunnel"
mkdir -p "$bin_dir"

cp "$script_dir/ssh-start.sh" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/ssh-start.sh"
chmod 755 "$bin_dir/ssh-start.sh"

cp "$script_dir/ssh-watchdog.sh" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/ssh-watchdog.sh"
chmod 755 "$bin_dir/ssh-watchdog.sh"

cp "$script_dir/ssh-stop.sh" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/ssh-stop.sh"
chmod 755 "$bin_dir/ssh-stop.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="ssh-tunnel-for-user.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/ssh-start.sh \"$config_dir/config.ini\"|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/ssh-stop.sh \"$config_dir/config.ini\"|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

