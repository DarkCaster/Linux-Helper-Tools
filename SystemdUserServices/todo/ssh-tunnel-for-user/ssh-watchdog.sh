#!/bin/bash

extlog=""

log () {
 local msg="$@"
 logger -t ssh-watchdog.sh -i "$msg"
 test "z$extlog" != "z" && echo "$msg" >> "$extlog"
 true
}

config_ini="$1"
profile="$2"

. __CFGHELPER/cfg-helper.sh.in "$config_ini"

do_exit () {
 local code="$1"
 config_teardown
 log "exiting with code $code"
 exit $code
}

log "$profile: preparing ssh tunnel"

thisuser=`id -u`
thisusername=`whoami`

pidfile="/tmp/ssh-tunnel-user-$thisuser-$profile.pid"
pid=`cat "$pidfile" 2>/dev/null`

check_ssh_is_running() {
#1>&2 echo "debug check_ssh_is_running: pid=$pid"
 test "z$pid" = "z" && echo "false" && return
 local check=`ps --no-headers -o pid:1,comm:1 -u "$thisusername" | grep -e "^$pid ssh\$" | wc -l`
#1>&2 echo "debug check_ssh_is_running: check=$check"
 test "z$check" = "z0" && echo "false" || echo "true"
}

test "`check_ssh_is_running`" = "true" && log "$profile: ssh tunnel already running" && do_exit 0

#log string
logfile=`read_param "$profile" log`
test "z$logfile" = "z" && log "$profile: log param missing" && logfile="/tmp/ssh-tunnel-user-$thisuser-$profile.log"

touch "$logfile"
chmod 600 "$logfile"

#connect string
connect=`read_param "$profile" connect`
test "z$connect" = "z" && log "$profile: connect param missing" && do_exit 5

#options
options=`read_param "$profile" options` 
test "z$options" = "z" && log "$profile: options param missing" && do_exit 4

#ssh key identy
key=`read_param "$profile" key`
test "z$key" != "z" && test ! -f "$key" && log "$profile: keyfile $key is not exist" && do_exit 3
test "z$key" != "z" && chmod 600 "$key"

#restarts
restarts=`read_param "$profile" restarts` 
test "z$restarts" = "z" && log "$profile: restarts param missing" && restarts="10"

#sleep
sleep=`read_param "$profile" sleep` 
test "z$sleep" = "z" && log "$profile: sleep param missing" && sleep="5"

restart_ssh() {
 #start
 log "$profile: starting ssh tunnel"
 local key_sw=""
 test "z$key" != "z" && key_sw="-i"
 2>/dev/null ssh $connect $options $key_sw "$key" -N -T -x -v -E "$logfile" &
 #check pid
 pid="$!"
 test "`check_ssh_is_running`" = "false" && pid=""
 #write pid
 echo "$pid" > "$pidfile"
 chmod 600 "$pidfile"
}

restart_ssh
test "`check_ssh_is_running`" = "false" && log "$profile: ssh tunnel startup failed!" && do_exit 2
log "$profile: ssh tunnel startup complete"

#wait and check
wait "$pid"
code="$?"
test "z$code" = "z0" && restarts="0" && log "$profile: ssh tunnel clean shutdown"

while [ "z$restarts" != "z0" ]
do
 #restart on error
 log "$profile: ssh tunnel failed with error, restarts left=$restarts"
 sleep $sleep
 rm -f "$pidfile"
 restarts=`expr $restarts - 1`
 restart_ssh
 if [ "`check_ssh_is_running`" = "false" ]; then
  continue
 else
  log "$profile: ssh tunnel restart complete"
  wait "$pid"
  code="$?"
  test "z$code" = "z0" && restarts="0" && log "$profile: ssh tunnel clean shutdown"
 fi
done

rm -f "$pidfile"

do_exit 0

