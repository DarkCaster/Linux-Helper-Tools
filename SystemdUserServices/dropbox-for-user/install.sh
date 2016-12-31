#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# install systemd for desktop helper
"$script_dir/../../SystemdForDesktopUser/install.sh"

#user-service-directory
unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"

dropbox=`which dropbox 2> /dev/null`
if [ "z$dropbox" = "z" ]; then
 echo "dropbox binary not found. exiting."
 exit 1
fi

#auto-mounter-scripts
bin_dir="$HOME/apps/systemd-services/dropbox-for-user"
mkdir -p "$bin_dir"

cp "$script_dir/dropbox-start.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/dropbox-start.sh"
sed -i -e "s|__DROPBOX|$dropbox|g" "$bin_dir/dropbox-start.sh"
chmod 755 "$bin_dir/dropbox-start.sh"

cp "$script_dir/dropbox-stop.sh" "$bin_dir"
sed -i -e "s|__HOME|$HOME|g" "$bin_dir/dropbox-stop.sh"
sed -i -e "s|__DROPBOX|$dropbox|g" "$bin_dir/dropbox-stop.sh"
chmod 755 "$bin_dir/dropbox-stop.sh"

unit="dropbox.service"
cp "$script_dir/service.template" "/tmp/$unit"
sed -i -e "s|__start|$bin_dir/dropbox-start.sh|g" "/tmp/$unit"
sed -i -e "s|__stop|$bin_dir/dropbox-stop.sh|g" "/tmp/$unit"
mv "/tmp/$unit" "$unit_dir/$unit"

systemctl --user daemon-reload


