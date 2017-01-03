#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#config
config_dir="$HOME/.config/istgt-for-user"
mkdir -p "$config_dir"

test ! -f "$config_dir/auth.conf" && test -f "$script_dir/config/auth.conf" && echo "copying custom auth.conf" && cp "$script_dir/config/auth.conf" "$config_dir/auth.conf"
test ! -f "$config_dir/auth.conf" && cp "$script_dir/auth.conf" "$config_dir"

test ! -f "$config_dir/istgt.conf" && test -f "$script_dir/config/istgt.conf" && echo "copying custom istgt.conf" && cp "$script_dir/config/istgt.conf" "$config_dir/istgt.conf"

if [ ! -f "$config_dir/istgt.conf" ]; then
 cp "$script_dir/istgt.conf" "$config_dir"
 sed -i -e "s|__auth.conf|$config_dir/auth.conf|g" "$config_dir/istgt.conf"
 sed -i -e "s|__media.directory|$config_dir/media|g" "$config_dir/istgt.conf"
fi

#service start and stop scripts
bin_dir="$HOME/apps/systemd-services/istgt"
mkdir -p "$bin_dir"
cp "$script_dir/iscsi-start.sh" "$bin_dir"
chmod 755 "$bin_dir/iscsi-start.sh"
cp "$script_dir/iscsi-stop.sh" "$bin_dir"
chmod 755 "$bin_dir/iscsi-stop.sh"
cp "$script_dir/iscsi-post.sh" "$bin_dir"
chmod 755 "$bin_dir/iscsi-post.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="istgt-for-user.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/iscsi-start.sh \"$config_dir/istgt.conf\"|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/iscsi-stop.sh|g" "/tmp/$unit"
sed -i -e "s|__dir|$bin_dir|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload

