#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
cd "$script_dir"

if [[ -z $PREFIX ]]; then
  PREFIX="$1"
  [[ -z $PREFIX ]] && PREFIX="/usr/local"
fi

if [[ -z $CONFIG_DIR ]]; then
  CONFIG_DIR="$2"
  [[ -z $CONFIG_DIR ]] && CONFIG_DIR="/etc"
fi

mkdir -p "$PREFIX/bin"
cp "$script_dir/clr-ucode-updater.sh" "$PREFIX/bin/clr-ucode-updater.sh"
sed -i "s|__etc|$CONFIG_DIR|g" "$PREFIX/bin/clr-ucode-updater.sh"
chmod 755 "$PREFIX/bin/clr-ucode-updater.sh"

mkdir -p "$CONFIG_DIR"
if [[ ! -f "$CONFIG_DIR/clr-ucode-updater.cfg" ]]; then
  cp "$script_dir/clr-ucode-updater.cfg" "$CONFIG_DIR/clr-ucode-updater.cfg"
  chmod 644 "$CONFIG_DIR/clr-ucode-updater.cfg"
fi
