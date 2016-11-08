#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: iscsi-connect.sh <config file, optionally relative to config dir> [yes\no - use zenity for error reporting, default no]"
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

test ! -z "$portal"
check_errors "portal variable not set"

test ! -z "$iqn"
check_errors "iqn variable not set"

log "performing discovery"
iscsiadm -m discovery -t st -p $portal
check_errors "discovery failed"

log "performing login"
iscsiadm --mode node --targetname $iqn --portal $portal --login
check_errors "iscsi connection failed"

