#!/bin/bash

set -e

#load config
. "__etc/clr-ucode-updater.cfg"

mount_dir=`mktemp -d -t boot_XXXXXX`

echo "mounting $efi_dev to $mount_dir"
mount -t vfat -o rw,defaults "$efi_dev" "$mount_dir"

ucode_line="initrd /ucode/intel-ucode.img"

while IFS= read -r cfg_file
do
  echo "processing $cfg_file"
  if ! `grep -qF -- "$ucode_line" "$cfg_file"`; then
    echo "adding line $ucode_line to config file $cfg_file"
    sed -i "/^linux.*/a $ucode_line" "$cfg_file"
    printf "\nresult:\n" && cat "$cfg_file" && echo ""
  else
    echo "skipping file $cfg_file"
  fi
done < <(find "$mount_dir/loader/entries" -type f -name "*.conf")

echo "umounting $mount_dir"
umount "$mount_dir"

echo "removing temp dir $mount_dir"
rmdir "$mount_dir"
