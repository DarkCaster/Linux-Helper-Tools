#!/bin/bash

#should be run as root

script_dir="$(cd "$(dirname "$0")" && pwd)"

set -e

initdir="/etc/modules-load.d"
confdir="/etc/modprobe.d"
mkdir -p "$initdir"
mkdir -p "$confdir"

echo "installing config file for zram module to $confdir/zram.conf"
cp "$script_dir/zram.conf" "$confdir/zram.conf"
chmod 640 "$confdir/zram.conf"

echo "installing init file for zram module to $initdir/zram.conf"
echo "zram" > "$initdir/zram.conf"
chmod 640 "$initdir/zram.conf"
