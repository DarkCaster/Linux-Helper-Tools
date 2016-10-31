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

#try to use locally extracted shim and grub rpm, from opensuse
test -d "${script_dir}/local/shim" && echo "using local shim binaries" && source_dir_shim="${script_dir}/local/shim${source_dir_shim}"
test -d "${script_dir}/local/grub" && echo "using local grub binaries" && source_dir_grub="${script_dir}/local/grub${source_dir_grub}" && extra_dir_grub="${script_dir}/local/grub${extra_dir_grub}"

show_usage () {
 echo "usage: shim-install-portable.sh <destination dir (mounted efi partition directory)>"
 exit 100
}

log () {
 local msg="$@"
 echo "$msg"
}

check_errors () {
 local status="$?"
 local msg="$@"
 if [ "$status" != "0" ]; then
  if [ "z$msg" != "z" ]; then
   log "$msg"
  else
   log "ERROR: last operation finished with error code $status"
  fi
  exit $status
 fi
}

#destination dir
efibase="$@"
test -z "${efibase}" && show_usage

test -d "${efibase}"
check_errors "destination dir is not exist"

test -d "${source_dir_shim}"
check_errors "source_dir_shim ${source_dir_shim} is not exist"

efidir="${efibase}/EFI/BOOT"

#cleanup old installations
rm -rf "${efibase}/boot"
check_errors "failed to remove ${efibase}/boot dir"

rm -rf "${efibase}/BOOT"
check_errors "failed to remove ${efibase}/BOOT dir"

rm -rf "${efidir}"
check_errors "failed to remove ${efidir} dir"

#create dir and install required binaries
mkdir -p "${efidir}"
check_errors "failed to create ${efidir} dir"

cp "${source_dir_shim}/shim.efi" "${efidir}/boot${efi_arch}.efi"
check_errors

cp "${source_dir_shim}/shim"*.der "${efidir}"
check_errors

cp "${source_dir_shim}/MokManager.efi" "${efidir}"
check_errors

cp "${script_dir}/grub-secure.cfg" "${efidir}/grub.cfg"
check_errors

sed -i "s|__vendor__|BOOT|g" "${efidir}/grub.cfg"
check_errors

if [ "z${grub_override_arch}" = "zy" ]; then
 cp "${source_dir_grub}/grub.efi" "${efidir}"
 check_errors
 cp "${source_dir_grub}/grub.der" "${efidir}"
 check_errors
else
 cp "${source_dir_grub}/grub.efi" "${efidir}/grub${efi_arch}.efi"
 check_errors
 cp "${source_dir_grub}/grub.der" "${efidir}/grub${efi_arch}.der"
 check_errors
fi

cp "${extra_dir_grub}/unicode.pf2" "${efidir}"
check_errors

#copy local public keys
if [ -d "${script_dir}/keys" ]; then
 cp "${script_dir}/keys/"*.der "${efidir}"
 check_errors
fi

