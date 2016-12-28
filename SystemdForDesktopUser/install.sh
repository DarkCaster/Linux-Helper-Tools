#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# main script. it will prepare systemd env
# and start user services installed with "desktop.target"
target_dir="$HOME/.bin"
mkdir -p "$target_dir"
script="$target_dir/systemd-desktop-startup-script.sh"
cp "$script_dir/systemd-desktop-startup-script.sh" "$script"
chmod 755 "$script"

# autostart dir
autostart_dir="$HOME/.config/autostart"
mkdir -p "$autostart_dir"

# autostart desktop file.
desktop_file="$autostart_dir/systemd-for-desktop.desktop"
cp "$script_dir/systemd-for-desktop.desktop" "$desktop_file"
sed -i -e "s|__exec|$script|g" "$desktop_file"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

cp "$script_dir/desktop.target"  "$unit_dir/desktop.target"
cp "$script_dir/desktop.service" "$unit_dir/desktop.service"

sed -i -e "s|__start|/bin/true|g" "$unit_dir/desktop.service"
sed -i -e "s|__stop|/bin/false|g" "$unit_dir/desktop.service"

systemctl --user daemon-reload

