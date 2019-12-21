#!/bin/sh

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

# service scripts
bin_dir="$HOME/apps/systemd-services/custom-pulseaudio"
mkdir -p "$bin_dir"
mkdir -p "$bin_dir/pulse-modules"

cp "$script_dir/pulse-start.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/pulse-start.sh"
sed -i -e "s|__BIN|$bin_dir|g" "$bin_dir/pulse-start.sh"
chmod 755 "$bin_dir/pulse-start.sh"

cp "$script_dir/pulse-stop.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/pulse-stop.sh"
sed -i -e "s|__BIN|$bin_dir|g" "$bin_dir/pulse-stop.sh"
chmod 755 "$bin_dir/pulse-stop.sh"

cp "$script_dir/save-alsa-levels.sh" "$bin_dir"
chmod 755 "$bin_dir/save-alsa-levels.sh"

cp "$script_dir/restore-alsa-levels.sh" "$bin_dir"
chmod 755 "$bin_dir/restore-alsa-levels.sh"

# tune this files for your needs
cp "$script_dir/daemon.conf" "$bin_dir"
cp "$script_dir/default.pa" "$bin_dir"

# user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

unit="custom-pulseaudio.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__dir|$bin_dir|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload
systemctl --user enable custom-pulseaudio.service

