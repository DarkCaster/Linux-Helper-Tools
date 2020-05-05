#!/bin/bash

#should be run as root

script_dir="$(cd "$(dirname "$0")" && pwd)"

set -e

target="$1"
[[ -z $target ]] && target="/usr/local"

[[ ! -d "$target/bin" ]] && echo "creating target directory: $target/bin" && mkdir -p "$target/bin"

echo "installing zramtool utility script"
cp "$script_dir/zramtool" "$target/bin"
chmod 755 "$target/bin/zramtool"

echo "installing zraminit.service"
cp "$script_dir/zraminit.service" "/tmp/zraminit.service"
zramtool_bin=$(which 2>/dev/null zramtool || true)
[[ -z "$zramtool_bin" ]] && echo "cannot detect zramtool binary!" && exit 1
sed -i -e "s|__zramtool|$zramtool_bin|g" "/tmp/zraminit.service"
mkdir -p "/etc/systemd/system"
mv "/tmp/zraminit.service" "/etc/systemd/system/zraminit.service"

systemctl daemon-reload
systemctl enable zraminit.service
