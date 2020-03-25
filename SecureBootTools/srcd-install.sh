#!/bin/bash

#download sysrescuecd, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/6.1.1/systemrescuecd-amd64-6.1.1.iso/download"
sha256="836e5fb7853681e5e425b43f77962be1aee1f1aab3690846cb5123832c3f415d"

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

show_usage () {
 echo "usage: srcd-install.sh <EFI partition label> <destination dir (mounted efi partition directory)>"
 exit 100
}

#destination dir
efilabel="$1"
[[ -z "${efilabel}" ]] && show_usage
efibase="$2"
[[ -z "${efibase}" ]] && show_usage
[[ ! -d "${efibase}" ]] && echo "destination dir is not exist" && exit 1

#create local dir and download rpms
mkdir -p "$script_dir/local"
olddir=`pwd`
cd "${script_dir}/local"

if [[ ! -e "srcd.iso" ]]; then
 echo "downloading sysrescuecd"
 wget "$url" -O srcd.iso
fi

echo "checking image integrity"
checksum=`sha256sum -b srcd.iso | awk '{print $1}'`
[[ $checksum != $sha256 ]] && echo "integrity check failed!" && exit 1

echo "cleaning up"
rm -f "vmlinuz.signed"
rm -f "vmlinuz"
rm -f "sysresccd.img"
rm -f "amd_ucode.img"
rm -f "intel_ucode.img"

echo "extracting kernel"
7z e srcd.iso sysresccd/boot/x86_64/vmlinuz 1>/dev/null
7z e srcd.iso sysresccd/boot/x86_64/sysresccd.img 1>/dev/null
7z e srcd.iso sysresccd/boot/amd_ucode.img 1>/dev/null
7z e srcd.iso sysresccd/boot/intel_ucode.img 1>/dev/null

cd "${olddir}"

echo "signing kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/vmlinuz" "${script_dir}/local/vmlinuz.signed"

#cleanup
echo "cleaning up old srcd installation at ${efibase}"
rm -rf "${efibase}/srcd"

#deploy
echo "deploying files to ${efibase}"
mkdir -p "${efibase}/srcd"
cp "${script_dir}/local/vmlinuz.signed" "${efibase}/srcd"
cp "${script_dir}/local/sysresccd.img" "${efibase}/srcd"
cp "${script_dir}/local/amd_ucode.img" "${efibase}/srcd"
cp "${script_dir}/local/intel_ucode.img" "${efibase}/srcd"
cp "${script_dir}/local/srcd.iso" "${efibase}/srcd"
cp "${script_dir}/grub-sysrescuecd.cfg.in" "${efibase}/srcd/grub.cfg.in"
sed -i -e "s|__EFI_LABEL__|${efilabel}|g" "${efibase}/srcd/grub.cfg.in"
