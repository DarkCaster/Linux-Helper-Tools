#!/bin/bash

#download kubuntu, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="http://cdimage.ubuntu.com/kubuntu/releases/20.04/release/kubuntu-20.04-desktop-amd64.iso"
sha256="ffddf52ad0122180a130f1d738a9a2cb77d87848a326a16cf830ac871a3c786f"

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

show_usage () {
 echo "usage: kubuntu-install.sh <EFI partition label> <destination dir (mounted efi partition directory)>"
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

if [[ ! -e "kubuntu.iso" ]]; then
 echo "downloading kubuntu"
 wget "$url" -O kubuntu.iso
fi

echo "checking image integrity"
checksum=`sha256sum -b kubuntu.iso | awk '{print $1}'`
[[ $checksum != $sha256 ]] && echo "integrity check failed!" && exit 1

echo "cleaning up"
rm -rf ".disk"
rm -rf "casper"
rm -rf "dists"
rm -rf "pool"
rm -rf "preseed"
rm -rf "README.diskdefines"

echo "extracting live-image"
7z x kubuntu.iso ".disk/*" 1>/dev/null
7z x kubuntu.iso "casper/*" 1>/dev/null
7z x kubuntu.iso "dists/*" 1>/dev/null
7z x kubuntu.iso "pool/*" 1>/dev/null
7z x kubuntu.iso "preseed/*" 1>/dev/null
7z e kubuntu.iso "README.diskdefines" 1>/dev/null

cd "${olddir}"

echo "removing original signature"
pesign -u 0 -r -i "${script_dir}/local/casper/vmlinuz" -o "${script_dir}/local/casper/vmlinuz.tmp"

echo "signing kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/casper/vmlinuz.tmp" "${script_dir}/local/casper/vmlinuz.signed"

#cleanup
rm "${script_dir}/local/casper/vmlinuz.tmp"
echo "cleaning up old kubuntu installation at ${efibase}"
rm -rf "${efibase}/kubuntu"

#deploy
echo "deploying files to ${efibase}"
mkdir -p "${efibase}/kubuntu"

cp -r "${script_dir}/local/.disk" "${efibase}/kubuntu/"
cp -r "${script_dir}/local/casper" "${efibase}/kubuntu/"
cp -r "${script_dir}/local/dists" "${efibase}/kubuntu/"
cp -r "${script_dir}/local/pool" "${efibase}/kubuntu/"
cp -r "${script_dir}/local/preseed" "${efibase}/kubuntu/"
cp -r "${script_dir}/local/README.diskdefines" "${efibase}/kubuntu/"
cp "${script_dir}/grub-kubuntu.cfg.in" "${efibase}/kubuntu/grub.cfg.in"
sed -i -e "s|__EFI_LABEL__|${efilabel}|g" "${efibase}/kubuntu/grub.cfg.in"
