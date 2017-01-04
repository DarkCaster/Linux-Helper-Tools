#!/bin/bash

showusage () {
 echo "Usage: stunnel-start.sh <config.ini>"
}

extlog=""

log () {
 local msg="$@"
 echo "stunnel-start.sh: $msg"
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

log "creating stunnel ctrldir"
mkdir -p "$ctrldir"
test "z$?" != "z0" && log "failed to create stunnel ctrldir at $ctrldir" && do_exit 8

extlog="$ctrldir/start.log"

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

if [ "`check_stunnel_is_running`" = "true" ]; then
 log "stunnel instance already running"
 do_exit 5
fi

log "securing stunnel ctrldir"
chmod 700 "$ctrldir"
test "z$?" != "z0" && log "failed to secure stunnel ctrldir at $ctrldir" && do_exit 4

config="$ctrldir/config.ini"

log "preparing stunnel config file"
echo -n "" > "$config"
test "z$?" != "z0" && log "failed to prepare stunnel config at $config" && do_exit 3

prepend_string() {
 local string="$@"
 echo "$string" > "$ctrldir/pre"
 cat "$config" > "$ctrldir/post"
 cat "$ctrldir/pre" "$ctrldir/post" > "$config"
 true
}

append_string() {
 local string="$@"
 echo "$string" >> "$config"
 true
}

cleanup_gen() {
 rm -f "$ctrldir/pre"
 rm -f "$ctrldir/post"
 true
}

append_string "output = $ctrldir/stunnel.log"
append_string "pid = $pidfile"
append_string "foreground = no"

list_sections | grep -i "^stunnel-" | while read profile
do
 subsection=`echo "$profile" | sed "s|^stunnel-||"`
 test "z$subsection" = "z" &&  log "incorrect stunnel config subsection name" && continue
 log "generating $subsection stunnel config section"
 test "z$subsection" != "zglobal" && append_string "[$subsection]"
 list_params "$profile" | while read par
 do
  test "z$par" = "zoutput" && log "output stunnel config parameter is prohibited. skipping." && continue
  test "z$par" = "zpid" && log "pid stunnel config parameter is prohibited. skipping." && continue
  test "z$par" = "zforeground" && log "foreground stunnel config parameter is prohibited. skipping." && continue
  val=`read_param "$profile" "$par"`
  log "adding parameter: $par = $val"
  test "z$subsection" = "zglobal" && prepend_string "$par = $val" || append_string "$par = $val"
 done
done

log "removing temporary files from config generation"
cleanup_gen

log "securing stunnel config file"
chmod 600 "$config"
test "z$?" != "z0" && log "failed to secure stunnel config at $config" && do_exit 2

log "starting stunnel"
$stunnel "$config" >> "$ctrldir/stunnel-stdout-stderr.log" 2>&1 &

log "waiting for startup complete"
wait_for_pid created "$pidfile"

pid=`cat "$pidfile" 2>/dev/null`

if [ "`check_stunnel_is_running`" = "false" ]; then
 log "stunnel instance startup failed"
 do_exit 1
fi

do_exit 0

