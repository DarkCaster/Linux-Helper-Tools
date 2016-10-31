#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: create-luks-header.sh <device path>"
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


get_serial () {
 local dpath="$1"
 local serial=`2>/dev/null udevadm info --query=property --name="$dpath" | grep -e "SCSI_IDENT_SERIAL" | sed "s|^SCSI_IDENT_SERIAL=||"`
 echo "$serial"
}

device="$@"
test -z "$device" && show_usage

test -f "$script_dir/user.cfg.sh.in"
check_errors "config file with user credentials is missing"

. "$script_dir/user.cfg.sh.in"
check_errors "error while sourcing config file with user credentials"

mkdir -p "$script_dir/config"
check_errors

chown $user:$group "$script_dir/config"
check_errors

test -e "$device"
check_errors "given device path is not exist"

serial=`get_serial "$device"`
test -z "$serial" && log "cannot read drive serial, exiting" && exit 100

if [ ! -f "$script_dir/config/luks_header_$serial" ]; then
 log "creating luks header-storage file at $script_dir/config/luks_header_$serial"
 dd if=/dev/zero of="$script_dir/config/luks_header_$serial" bs=1M count=2
 check_errors
fi

cryptsetup --cipher=aes-xts-plain64 --key-size=256 --hash=sha512 luksFormat "$device" --header "$script_dir/config/luks_header_$serial" --align-payload=0
check_errors

log "changing owner of header file"
chown $user:$group "$script_dir/config/luks_header_$serial"
check_errors

