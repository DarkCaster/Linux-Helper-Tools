#!/bin/bash

showusage () {
 echo "Usage: stunnel-stop.sh <config.ini>"
}

extlog=""

log () {
 local msg="$@"
 echo "stunnel-stop.sh: $msg"
 test "z$extlog" != "z" && echo "$msg" >> "$extlog"
 true
}

proc_try=0
waittime=10

wait_for_pid () {
 proc_try=0
 while test $proc_try -lt $waittime ; do
 case "$1" in
  'created')
   if [ -f "$2" ] ; then proc_try=''; break; fi
  ;;
  'removed')
   if [ ! -f "$2" ] ; then proc_try=''; break; fi
  ;;
 esac
 proc_try=`expr $proc_try + 1`
 sleep 1
 done
}

config_ini="$1"
test ! -f "$config_ini" && showusage && exit 200

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

. __CFGHELPER/cfg-helper.sh.in "$config_ini"

do_exit () {
 local code="$1"
 config_teardown
 log "exiting with code $code"
 exit $code
}

if [ `check_section "main"` = "false" ]; then
 log "main section disabled or missing"
 do_exit 10
fi

ctrldir=`read_param "main" ctrldir`
if [ "z$ctrldir" = "z" ]; then
 log "ctrldir config parameter missing!"
 do_exit 9
fi

log "checking stunnel ctrldir"
test ! -d "$ctrldir" && log "stunnel ctrldir missing at $ctrldir" && do_exit 8

extlog="$ctrldir/stop.log"

stunnel=`which stunnel 2>/dev/null`
test "z$stunnel" = "z" && stunnel=`which /usr/sbin/stunnel 2>/dev/null`

if [ "z$stunnel" = "z" ]; then
 log "stunnel binary is missing"
 do_exit 7
fi

uid=`read_param "main" uid`
if [ "z$uid" = "z" ]; then
 log "uid config parameter missing!"
 do_exit 6
fi

thisuser=`id -u`
thisusername=`whoami`

pidfile="$ctrldir/stunnel.pid"
pid=`cat "$pidfile" 2>/dev/null`

check_stunnel_is_running() {
 test "z$pid" = "z" && echo "false" && return
 local check=`ps --no-headers -o pid:1,cmd:1 -u "$thisusername" | grep -e "^$pid $stunnel" | wc -l`
 test "z$check" = "z0" && echo "false" || echo "true"
}

if [ "`check_stunnel_is_running`" = "false" ]; then
 log "stunnel instance is not running"
 do_exit 0
fi

log "terminating stunnel process"
kill -TERM $pid

log "waiting for shutdown complete"
wait_for_pid removed "$pidfile"

sleep 1

if [ "`check_stunnel_is_running`" = "true" ]; then
 log "stunnel instance shutdown failed"
 do_exit 1
fi

do_exit 0

