#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"

#read basedir.cfg
basedir=`cat "$script_dir/basedir.cfg" | head -n1`

#create basedir
mkdir -p "$basedir"

#create directories
echo "creating directories"
for d in hooks qemu secrets storage certs dump ram
do
  [[ ! -d  $basedir/$d ]] && mkdir "$basedir/$d"
done

echo "installing sample configs"
for f in qemu.conf lxc.conf libvirtd.conf libvirt.conf libvirt-admin.conf
do
  [[ ! -f $basedir/$f ]] && \
  cp "$script_dir/sample_configs/$f" "$basedir" && \
  sed -i "s|__basedir__|""$basedir""|g" "$basedir/$f"
done
