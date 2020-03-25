#!/bin/bash

#download clonezilla, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="none"
sha256="836e5fb7853681e5e425b43f77962be1aee1f1aab3690846cb5123832c3f415d"

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

show_usage () {
 echo "usage: clonezilla-install.sh <destination dir (mounted efi partition directory)>"
 exit 100
}

#destination dir
efibase="$@"
[[ -z "${efibase}" ]] && show_usage
[[ ! -d "${efibase}" ]] && echo "destination dir is not exist" && exit 1

#create local dir and download rpms
mkdir -p "$script_dir/local"
olddir=`pwd`
cd "${script_dir}/local"

if [[ ! -e "clonezilla.iso" ]]; then
 echo "downloading clonezilla"
 wget "$url" -O clonezilla.iso
 checksum=`sha256sum -b clonezilla.iso | awk '{print $1}'`
 [[ $checksum != $sha256 ]] && echo "integrity check failed!" && exit 1
fi

echo "cleaning up"
rm -f "vmlinuz.signed"
rm -f "vmlinuz"
rm -f "initrd.img"

echo "extracting kernels"
7z e clonezilla.iso live/vmlinuz 1>/dev/null
7z e clonezilla.iso live/initrd.img 1>/dev/null

cd "${olddir}"

echo "signing kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/vmlinuz" "${script_dir}/local/vmlinuz.signed"

#cleanup
echo "cleaning up old clonezilla installation at ${efibase}"
rm -rf "${efibase}/clonezilla"

#deploy
echo "deploying files to ${efibase}"
mkdir -p "${efibase}/clonezilla"
cp "${script_dir}/local/vmlinuz.signed" "${efibase}/clonezilla"
cp "${script_dir}/local/initrd.img" "${efibase}/clonezilla"
cp "${script_dir}/local/clonezilla.iso" "${efibase}/clonezilla"
cp "${script_dir}/grub-clonezilla.cfg.in" "${efibase}/clonezilla/grub.cfg.in"
