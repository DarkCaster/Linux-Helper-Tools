#!/bin/bash

#download sysrescuecd, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/5.2.0/systemrescuecd-x86-5.2.0.iso/download"

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

show_usage () {
 echo "usage: srcd-install.sh <destination dir (mounted efi partition directory)>"
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

if [[ ! -e "srcd.iso" ]]; then
 echo "downloading sysrescuecd"
 wget "$url" -O srcd.iso
fi

echo "cleaning up"
rm -f "rescue64.signed"
rm -f "rescue64"
rm -f "altker64.signed"
rm -f "altker64"
rm -f "initram.igz"

echo "extracting kernels"
7z e srcd.iso isolinux/rescue64 1>/dev/null
7z e srcd.iso isolinux/initram.igz 1>/dev/null

cd "${olddir}"

echo "signing rescue64 kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/rescue64" "${script_dir}/local/rescue64.signed"

#cleanup
echo "cleaning up old srcd installation at ${efibase}"
rm -rf "${efibase}/srcd"

#deploy
echo "deploying files to ${efibase}"
mkdir -p "${efibase}/srcd"
cp "${script_dir}/local/rescue64.signed" "${efibase}/srcd"
cp "${script_dir}/local/initram.igz" "${efibase}/srcd"
cp "${script_dir}/local/srcd.iso" "${efibase}/srcd"
cp "${script_dir}/grub-sysrescuecd.cfg.in" "${efibase}/srcd/grub.cfg.in"
