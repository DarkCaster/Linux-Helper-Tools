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

log "terminating ssh tunnels from $config_ini"

. __CFGHELPER/cfg-helper.sh.in "$config_ini"

do_exit () {
 local code="$1"
 config_teardown
 log "exiting with code $code"
 exit $code
}

thisuser=`id -u`
thisusername=`whoami`

check_ssh_is_running() {
 local pid="$1"
 test "z$pid" = "z" && echo "false" && return
 local check=`ps --no-headers -o pid:1,comm:1 -u "$thisusername" | grep -e "^$pid ssh\$" | wc -l`
 test "z$check" = "z0" && echo "false" || echo "true"
}

list_sections | while read profile
do
 pidfile="/tmp/ssh-tunnel-user-$thisuser-$profile.pid"
 pid=`cat "$pidfile" 2>/dev/null`
 test "`check_ssh_is_running $pid`" = "false" && continue
 log "$profile: terminating ssh tunnel with pid $pid"
 2>/dev/null kill -SIGTERM $pid
done

do_exit 0

