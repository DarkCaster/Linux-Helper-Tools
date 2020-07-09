#!/bin/bash

#download kubuntu, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="http://cdimage.ubuntu.com/kubuntu/releases/20.04/release/kubuntu-20.04-desktop-amd64.iso"
sha256="ffddf52ad0122180a130f1d738a9a2cb77d87848a326a16cf830ac871a3c786f"

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

show_usage () {
 echo "usage: kubuntu-install.sh <destination dir (mounted efi partition directory)>"
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

if [[ ! -e "kubuntu.iso" ]]; then
 echo "downloading kubuntu"
 wget "$url" -O kubuntu.iso
fi

echo "checking image integrity"
checksum=`sha256sum -b kubuntu.iso | awk '{print $1}'`
[[ $checksum != $sha256 ]] && echo "integrity check failed!" && exit 1

echo "cleaning up"
rm -f "vmlinuz.signed"
rm -f "vmlinuz"
rm -f "initrd.img"
rm -f "initrd"

echo "extracting kernel"
7z e kubuntu.iso casper/vmlinuz 1>/dev/null
7z e kubuntu.iso casper/initrd 1>/dev/null

cd "${olddir}"

echo "signing kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/vmlinuz" "${script_dir}/local/vmlinuz.signed"

#cleanup
echo "cleaning up old kubuntu installation at ${efibase}"
rm -rf "${efibase}/kubuntu"

#deploy
echo "deploying files to ${efibase}"
mkdir -p "${efibase}/kubuntu"
cp "${script_dir}/local/vmlinuz.signed" "${efibase}/kubuntu"
cp "${script_dir}/local/initrd" "${efibase}/kubuntu"
cp "${script_dir}/local/kubuntu.iso" "${efibase}/kubuntu"
cp "${script_dir}/grub-kubuntu.cfg.in" "${efibase}/kubuntu/grub.cfg.in"
