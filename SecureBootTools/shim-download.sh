#!/bin/bash

#download shim and grub binaries from opensuse distro, and extract to local directory
#for future use with shim-install-portable.sh script

#binaries from opensuse 42.2 repo. MokManager cannot be started directly from shim with this version.
#but it can be started from grub (which should be signed with the same certificate)
shim_url="http://download.opensuse.org/distribution/leap/42.2/repo/oss/suse/x86_64/shim-0.9-11.1.x86_64.rpm"
grub_url1="http://download.opensuse.org/distribution/leap/42.2/repo/oss/suse/x86_64/grub2-x86_64-efi-2.02~beta2-87.1.x86_64.rpm"
grub_url2="http://download.opensuse.org/distribution/leap/42.2/repo/oss/suse/x86_64/grub2-2.02~beta2-87.1.x86_64.rpm"

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

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

#create local dir and download rpms
mkdir -p "$script_dir/local"
check_errors

olddir=`pwd`

cd "$script_dir/local"
check_errors

wget "$shim_url" --no-verbose -O shim.rpm
check_errors

wget "$grub_url1" --no-verbose -O grub1.rpm
check_errors

wget "$grub_url2" --no-verbose -O grub2.rpm
check_errors

rm -rf "shim"
check_errors

rm -rf "grub"
check_errors

mkdir -p "shim"
check_errors

mkdir -p "grub"
check_errors

cd "shim"
check_errors

log "extracting shim rpm"
rpm2cpio ../shim.rpm | cpio --quiet -idm
check_errors

cd ..
check_errors

cd "grub"
check_errors

log "extracting grub rpms"

rpm2cpio ../grub1.rpm | cpio --quiet -idm
check_errors

rpm2cpio ../grub2.rpm | cpio --quiet -idm
check_errors

cd ..
check_errors

cd "$olddir"
check_errors

