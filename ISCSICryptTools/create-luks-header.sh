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

date=`date "+%Y-%m-%d_%H-%M"`

log "creating header storage at $script_dir/config/luks-header_$date"
dd if=/dev/urandom of="$script_dir/config/luks-header_$date" bs=1M count=2
check_errors

cryptsetup --cipher=aes-xts-plain64 --key-size=256 --hash=sha512 luksFormat "$device" --header "$script_dir/config/luks-header_$date" --align-payload=0
check_errors

log "changing owner of header file"
chown $user:$group "$script_dir/config/luks-header_$date"
check_errors

