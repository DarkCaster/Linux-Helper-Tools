#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#config
config_dir="$HOME/.config/tftp-for-user"
mkdir -p "$config_dir"

test ! -f "$config_dir/options.sh.in" && test -f "$script_dir/config/options.sh.in" && echo "copying custom options.sh.in" && cp "$script_dir/config/options.sh.in" "$config_dir/options.sh.in"
test ! -f "$config_dir/options.sh.in" && cp "$script_dir/options.sh.in" "$config_dir"

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/tftp"
mkdir -p "$bin_dir"
cp "$script_dir/tftp-start.sh" "$bin_dir"
chmod 755 "$bin_dir/tftp-start.sh"
cp "$script_dir/tftp-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/tftp-stop.sh"
cp "$script_dir/tftp-post.sh" "$bin_dir"
chmod 755 "$bin_dir/tftp-post.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="tftp-for-user.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/tftp-start.sh \"$config_dir/options.sh.in\"|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/tftp-stop.sh|g" "/tmp/$unit"
sed -i -e "s|__dir|$bin_dir|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

