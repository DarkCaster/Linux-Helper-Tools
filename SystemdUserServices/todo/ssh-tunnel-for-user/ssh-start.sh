#!/bin/bash

showusage () {
 echo "Usage: ssh-start.sh <config.ini>"
}

extlog=""

log () {
 local msg="$@"
 logger -t ssh-start.sh -i "$msg"
 test "z$extlog" != "z" && echo "$msg" >> "$extlog"
 true
}

config_ini="$1"
test ! -f "$config_ini" && showusage && exit 10

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

log "starting ssh tunnels from $config_ini"

. __CFGHELPER/cfg-helper.sh.in "$config_ini"

do_exit () {
 local code="$1"
 config_teardown
 log "exiting with code $code"
 exit $code
}

list_sections | while read profile
do
 "$script_dir/ssh-watchdog.sh" "$config_ini" "$profile" &
done

do_exit 0

