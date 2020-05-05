#!/bin/bash

#should be run as root

script_dir="$(cd "$(dirname "$0")" && pwd)"

set -e

target="$1"
[[ -z $target ]] && target="/usr/local"

[[ ! -d "$target/bin" ]] && echo "creating target directory: $target/bin" && mkdir -p "$target/bin"

echo "installing zramswap utility script"
cp "$script_dir/zramswap" "$target/bin"
chmod 755 "$target/bin/zramswap"

echo "installing zramswap.service"
cp "$script_dir/zramswap.service" "/tmp/zramswap.service"
zramswap_bin=$(which 2>/dev/null zramswap || true)
[[ -z "$zramswap_bin" ]] && echo "cannot detect zramswap binary!" && exit 1
sed -i -e "s|__zramswap|$zramswap_bin|g" "/tmp/zramswap.service"
mkdir -p "/etc/systemd/system"
mv "/tmp/zramswap.service" "/etc/systemd/system/zramswap.service"

systemctl daemon-reload
systemctl enable zramswap.service
