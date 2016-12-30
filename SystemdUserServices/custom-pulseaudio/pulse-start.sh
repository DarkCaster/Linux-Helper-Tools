#!/bin/sh
#

log () {
 local msg="$@"
 echo "$msg"
}

do_exit () {
 local code="$1"
 log "exiting with code $code"
 exit $code
}

script_dir="$( cd "$( dirname "$0" )" && pwd )"

checkproc="$checkproc"
if [ "$checkproc" == "" ]; then
 checkproc="/sbin/checkproc"
fi

waittime=5

check_proc () {
 local exec_cmd="$1"
 $checkproc -z "$exec_cmd"
 if [ "$?" = "0" ]; then
  echo "r"
 else
  echo "s"
 fi
}

wait_for_proc () {
 local try=0
 local action="$1"
 local exec_cmd="$2"
 while test $try -lt $waittime
 do
  case "$action" in
  'started')
   if [ `check_proc "$exec_cmd"` = "r" ]; then
    try=''
    break
   fi
  ;;
  'stopped')
   if [ `check_proc "$exec_cmd"` = "s" ]; then
    try=''
    break
   fi
  ;;
  esac
  try=`expr $try + 1`
  sleep 1
 done
 test -z "$try" && return 0
 return 1
}

#set base files and directories names
pulse=`which pulseaudio 2> /dev/null`

if [ ! -f __HOME/.config/pulse/client.conf ]; then
  echo "autospawn=no" > __HOME/.config/pulse/client.conf
fi

$pulse -k 2>/dev/null
if ! wait_for_proc stopped "$pulse" ; then
 log "pulseaudio server kill failed!"
 do_exit 3
fi

rm -rf __HOME/.config/pulse 2>/dev/null
if [ -d __HOME/.config/pulse ]; then
 log "failed to remove pulseaudio config dir"
 do_exit 2
fi

install -d __HOME/.config/pulse 2>/dev/null
socket=`cat "$script_dir/default.pa" | grep "module-native-protocol-unix" | grep "socket" | cut -d" " -f3 | cut -d"=" -f2`
echo "autospawn=no" > __HOME/.config/pulse/client.conf
test "z$socket" = "z" || echo "default-server=unix:$socket" >> __HOME/.config/pulse/client.conf
install "$script_dir/daemon.conf" __HOME/.config/pulse/daemon.conf
install "$script_dir/default.pa" __HOME/.config/pulse/default.pa

if [ `check_proc "$pulse"` = "r" ]; then
 log "pulseaudio still working and cannot be stopped!"
 do_exit 1
fi

$pulse
wait_for_proc started "$pulse"

do_exit $?

