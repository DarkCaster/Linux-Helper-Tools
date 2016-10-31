#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: iscsi-connect.sh <config file, optionally relative to config dir>"
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

test -z "$portal" && log "portal variable not set" && exit 100
test -z "$iqn" && log "iqn variable not set" && exit 100

log "performing discovery"
iscsiadm -m discovery -t st -p $portal
check_errors

log "performing login"
iscsiadm --mode node --targetname $iqn --portal $portal --login
check_errors

