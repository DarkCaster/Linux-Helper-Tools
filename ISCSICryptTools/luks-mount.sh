#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: luks-mount.sh <config file, optionally relative to config dir> [yes\no - use zenity for error reporting, default no]"
 exit 100
}

log () {
 local msg="$@"
 echo "$msg"
}

usezenity="no"

check_errors () {
 local status="$?"
 local msg="$@"
 local logger="log "
 test "$usezenity" = "yes" && logger="zenity --error --text="
 if [ "$status" != "0" ]; then
  if [ "z$msg" != "z" ]; then
   $logger"$msg"
  else
   $logger"ERROR: last operation finished with error code $status"
  fi
  exit $status
 fi
}

config="$1"
test -z "$config" && show_usage

usezenity="$2"
test -z "$usezenity" && usezenity="no"

test ! -f "$config" && config="$script_dir/config/$config"
test -f "$config"
check_errors "config file is missing"

. "$config"
check_errors "error while sourcing config file"

test ! -z "$device"
check_errors "device variable not set"

header="$header"
test ! -z "$header"
check_errors "header variable not set"

keyfile="$keyfile"
test ! -z "$keyfile" && test ! -f "$keyfile" && keyfile="$script_dir/config/$keyfile" && test ! -f "$keyfile" && keyfile=""

test ! -z "$mountdir"
check_errors "mountdir variable not set"

test ! -z "$mountcmd"
check_errors "mountcmd variable not set"

test ! -z "$cryptname"
check_errors "cryptname variable not set"

test -z "$timeout" && log "timeout variable not set, setting it to 10" && timeout="10"

test ! -f "$header" && header="$script_dir/config/$header"
test -f "$header"
check_errors "header file not found"

test -d "$mountdir"
check_errors "$mountdir directory is not exist"

log "checking mountpoint"
mountpoint -q "$mountdir"
if [ "$?" = "0" ]; then
 false
 check_errors "$mountdir already mounted"
fi

log "awaiting device $device"
check="false"
while test "$timeout" -gt 0 ; do
 test -e "$device" && check="true" && timeout="0"
 test "$check" = "false" && sleep 1 && timeout=`expr $timeout - 1`
done

if [ "$check" = "false" ]; then
 false
 check_errors "device $device does not appear in selected timeout"
fi

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
check_errors "failed to mount $device to $mountdir"

