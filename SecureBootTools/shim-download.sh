#!/bin/bash

#download shim and grub binaries from opensuse distro, and extract to local directory
#for future use with shim-install-portable.sh script

#binaries from opensuse 42.2 repo. MokManager cannot be started directly from shim with this version.
#but it can be started from grub (which should be signed with the same certificate)
shim_url="https://download.opensuse.org/distribution/leap/42.3/repo/oss/suse/x86_64/shim-0.9-17.10.x86_64.rpm"
grub_url1="https://download.opensuse.org/distribution/leap/42.3/repo/oss/suse/x86_64/grub2-x86_64-efi-2.02-2.6.x86_64.rpm"
grub_url2="https://download.opensuse.org/distribution/leap/42.3/repo/oss/suse/x86_64/grub2-2.02-2.6.x86_64.rpm"

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

#create local dir and download rpms
mkdir -p "$script_dir/local"
cd "$script_dir/local"
wget "$shim_url" --no-verbose -O shim.rpm
wget "$grub_url1" --no-verbose -O grub1.rpm
wget "$grub_url2" --no-verbose -O grub2.rpm
rm -rf "shim"
rm -rf "grub"
mkdir -p "shim"
mkdir -p "grub"
cd shim
echo "extracting shim rpm"
rpm2cpio ../shim.rpm | cpio --quiet -idm
cd ../grub
echo "extracting grub rpms"
rpm2cpio ../grub1.rpm | cpio --quiet -idm
rpm2cpio ../grub2.rpm | cpio --quiet -idm
