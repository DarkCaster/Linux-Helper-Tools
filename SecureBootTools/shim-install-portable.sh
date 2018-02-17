#!/bin/bash

#create portable SHIM+GRUB installation
#(it will run without modifying boot variables)

#set shim and grub source directory
source_dir_shim="/usr/lib64/efi"
source_dir_grub="/usr/lib64/efi"
extra_dir_grub="/usr/share/grub2"
#arch suffix
efi_arch="x64"
#override grub efi arch suffix
grub_override_arch="y"

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

#try to use locally extracted shim and grub rpm, from opensuse
test -d "${script_dir}/local/shim" && echo "using local shim binaries" && source_dir_shim="${script_dir}/local/shim${source_dir_shim}"
test -d "${script_dir}/local/grub" && echo "using local grub binaries" && source_dir_grub="${script_dir}/local/grub${source_dir_grub}" && extra_dir_grub="${script_dir}/local/grub${extra_dir_grub}"

show_usage () {
 echo "usage: shim-install-portable.sh <destination dir (mounted efi partition directory)>"
 exit 100
}

#destination dir
efibase="$@"
[[ -z "${efibase}" ]] && show_usage
[[ ! -d "${efibase}" ]] && echo "destination dir is not exist" && exit 1
[[ ! -d "${source_dir_shim}" ]] && echo "source_dir_shim ${source_dir_shim} is not exist" && exit 2

efidir="${efibase}/EFI/BOOT"
#cleanup old installations
rm -rf "${efibase}/boot"
rm -rf "${efibase}/BOOT"
rm -rf "${efidir}"
#create dir and install required binaries
mkdir -p "${efidir}"
cp "${source_dir_shim}/shim.efi" "${efidir}/boot${efi_arch}.efi"
cp "${source_dir_shim}/shim"*.der "${efidir}"
cp "${source_dir_shim}/MokManager.efi" "${efidir}"
cp "${script_dir}/grub-secure.cfg" "${efidir}/grub.cfg"
sed -i "s|__vendor__|BOOT|g" "${efidir}/grub.cfg"

if [[ "${grub_override_arch}" = "y" ]]; then
 cp "${source_dir_grub}/grub.efi" "${efidir}"
 cp "${source_dir_grub}/grub.der" "${efidir}"
else
 cp "${source_dir_grub}/grub.efi" "${efidir}/grub${efi_arch}.efi"
 cp "${source_dir_grub}/grub.der" "${efidir}/grub${efi_arch}.der"
fi

cp "${extra_dir_grub}/unicode.pf2" "${efidir}"

#copy local public keys
[[ -d "${script_dir}/keys" ]] && cp "${script_dir}/keys/"*.der "${efidir}"
