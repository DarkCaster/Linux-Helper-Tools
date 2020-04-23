#!/bin/bash

#should be run as root

script_dir="$(cd "$(dirname "$0")" && pwd)"

set -e

target="$1"
[[ -z $target ]] && target="/usr/local"

[[ ! -d "$target/bin" ]] && echo "creating target directory: $target/bin" && mkdir -p "$target/bin"

echo "adding cgusers group"
groupadd -r -f cgusers

echo "installing cgusers.service"
cp "$script_dir/cgusers.service" "/tmp/cgusers.service"
cgcreate_bin=$(which 2>/dev/null cgcreate || true)
[[ -z "$cgcreate_bin" ]] && echo "cannot detect cgcreate binary!" && exit 1
sed -i -e "s|__cgcreate|$cgcreate_bin|g" "/tmp/cgusers.service"
mkdir -p "/etc/systemd/system"
mv "/tmp/cgusers.service" "/etc/systemd/system/cgusers.service"

echo "installing cguser-exec.sh helper script"
cp "$script_dir/cguser-exec.sh" "$target/bin"
chmod 755 "$target/bin/cguser-exec.sh"

systemctl daemon-reload
systemctl enable cgusers.service
