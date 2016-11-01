#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: luks-mount.sh <config file, optionally relative to config dir>"
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

config="$@"
test -z "$config" && show_usage

test ! -f "$config" && config="$script_dir/config/$config"
test -f "$config"
check_errors "config file is missing"

. "$config"
check_errors "error while sourcing config file"

test -z "$device" && log "device variable not set" && exit 100
header="$header"
test -z "$header" && log "header variable not set" && exit 100
keyfile="$keyfile"
test ! -z "$keyfile" && test ! -f "$keyfile" && keyfile="$script_dir/config/$keyfile" && test ! -f "$keyfile" && keyfile=""
test -z "$mountdir" && log "mountdir variable not set" && exit 100
test -z "$mountcmd" && log "mountcmd variable not set" && exit 100
test -z "$cryptname" && log "cryptname variable not set" && exit 100
test -z "$timeout" && log "timeout variable not set, setting it to 10" && timeout="10"

test ! -f "$header" && header="$script_dir/config/$header"
test -f "$header"
check_errors "header file not found"

test -d "$mountdir"
check_errors "$mountdir directory is not exist"

log "checking mountpoint"
mountpoint -q "$mountdir" && log "$mountdir already mounted" && exit 100

log "awaiting device $device"
check="false"
while test "$timeout" -gt 0 ; do
 test -e "$device" && check="true" && timeout="0"
 test "$check" = "false" && sleep 1 && timeout=`expr $timeout - 1`
done
test "$check" = "false" && log "device $device does not appear in selected timeout" && exit 100

if [ -z "$keyfile" ]; then
 log "TODO: mount with password, exiting"
 exit 100
else
 log "performing cryptsetup with external keyfile"
 cryptsetup luksOpen --allow-discards --header="$header" --key-file="$keyfile" "$device" "$cryptname"
 check_errors
fi

log "mounting $device"
$mountcmd "/dev/mapper/$cryptname" "$mountdir"
check_errors

