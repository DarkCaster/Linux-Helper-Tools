#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
prefix="$1"
[[ -z "$prefix" ]] && prefix="/usr/local"

mkdir -p "$prefix/lib/systemd/system-generators"
mkdir -p "$prefix/bin"

script_name="bcache-stop.sh"
generator_name="bcache-stop-generator.sh"

cp "$script_dir/$generator_name" "$prefix/lib/systemd/system-generators"
sed -i "s|__bcache_stop_script__|$script|g" "$prefix/lib/systemd/system-generators/$generator_name.sh"
chown root:root "$prefix/lib/systemd/system-generators/$generator_name.sh"
chmod 750 "$prefix/lib/systemd/system-generators/$generator_name.sh"

cp "$script_dir/$script_name.sh" "$prefix/bin"
chown root:root "$prefix/bin/$script_name.sh"
chmod 750 "$prefix/bin/$script_name.sh"

systemctl daemon-reload
