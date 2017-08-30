#!/bin/bash

#download sysrescuecd, extract and sign kernel, deploy prepared configuration to selected efi-partition directory

url="https://sourceforge.net/projects/systemrescuecd/files/sysresccd-x86/5.0.3/systemrescuecd-x86-5.0.3.iso/download"

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: srcd-install.sh <destination dir (mounted efi partition directory)>"
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

#create local dir and download rpms
mkdir -p "$script_dir/local"
check_errors

olddir=`pwd`

cd "${script_dir}/local"
check_errors

if [ ! -e "srcd.iso" ]; then
 log "downloading sysrescuecd"
 wget "$url" -O srcd.iso
 check_errors
fi

log "cleaning up"
rm -f "rescue64.signed"
check_errors

rm -f "rescue64"
check_errors

rm -f "altker64.signed"
check_errors

rm -f "altker64"
check_errors

rm -f "initram.igz"
check_errors

log "extracting kernels"
7z e srcd.iso isolinux/rescue64 1>/dev/null
check_errors

7z e srcd.iso isolinux/initram.igz 1>/dev/null
check_errors

cd "${olddir}"
check_errors

log "signing rescue64 kernel"
"${script_dir}/sign-efi-binary.sh" "${script_dir}/local/rescue64" "${script_dir}/local/rescue64.signed"
check_errors

#cleanup
log "cleaning up old srcd installation at ${efibase}"
rm -rf "${efibase}/srcd"
check_errors

#deploy
log "deploying files to ${efibase}"

mkdir -p "${efibase}/srcd"
check_errors

cp "${script_dir}/local/rescue64.signed" "${efibase}/srcd"
check_errors

cp "${script_dir}/local/initram.igz" "${efibase}/srcd"
check_errors

cp "${script_dir}/local/srcd.iso" "${efibase}/srcd"
check_errors

cp "${script_dir}/grub-sysrescuecd.cfg.in" "${efibase}/srcd/grub.cfg.in"
check_errors

