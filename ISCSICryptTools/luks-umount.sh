#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: luks-umount.sh <config file, optionally relative to config dir> [yes\no - use zenity for error reporting, default no]"
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

test ! -z "$mountdir"
check_errors "mountdir variable not set"

test ! -z "$cryptname"
check_errors "cryptname variable not set"

test -z "$timeout" && log "timeout variable not set, setting it to 10" && timeout="10"

test -d "$mountdir"
check_errors "$mountdir directory is not exist"

log "checking mountpoint"
mountpoint -q "$mountdir"
check_errors "$mountdir not mounted"

log "unmounting $mountdir"
umount "$mountdir"
check_errors "umount $mountdir failed"

log "closing luks-crypt device"
cryptsetup luksClose "$cryptname"
check_errors "failed to close luks devie: $cryptname"


