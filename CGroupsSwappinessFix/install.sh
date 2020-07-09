#!/bin/bash

#should be run as root

script_dir="$(cd "$(dirname "$0")" && pwd)"

set -e

target="$1"
[[ -z $target ]] && target="/usr/local"

[[ ! -d "$target/bin" ]] && echo "creating target directory: $target/bin" && mkdir -p "$target/bin"

echo "installing cgswpfix utility script"
cp "$script_dir/cgswpfix" "$target/bin"
chmod 755 "$target/bin/cgswpfix"

echo "installing cgswpfix.service"
cp "$script_dir/cgswpfix.service" "/tmp/cgswpfix.service"
cgswpfix_bin=$(which 2>/dev/null cgswpfix || true)
[[ -z "$cgswpfix_bin" ]] && echo "cannot detect cgswpfix binary!" && exit 1
sed -i -e "s|__cgswpfix|$cgswpfix_bin|g" "/tmp/cgswpfix.service"
mkdir -p "/etc/systemd/system"
mv "/tmp/cgswpfix.service" "/etc/systemd/system/cgswpfix.service"

systemctl daemon-reload
systemctl enable cgswpfix.service
