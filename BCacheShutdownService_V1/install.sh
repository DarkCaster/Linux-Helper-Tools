#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
prefix="$1"

[[ -z "$service_dir" ]] && service_dir="/etc/systemd/system"
[[ -z "$prefix" ]] && prefix="/usr/local"
mkdir -p "$prefix/bin"

service="$service_dir/bcache-stop.service"
script="$prefix/bin/bcache-stop.sh"

cp "$script_dir/bcache-stop.service" "$service"
chown root:root "$service"
chmod 644 "$service"
sed -i -e "s|__bcache_stop_script__|$script|g" "$service"

cp "$script_dir/bcache-stop.sh" "$script"
chown root:root "$script"
chmod 750 "$script"

systemctl daemon-reload
systemctl stop bcache-stop.service
systemctl disable bcache-stop.service
systemctl enable bcache-stop.service
