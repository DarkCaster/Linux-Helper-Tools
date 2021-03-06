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

pgrep=`which pgrep 2> /dev/null`
if [ "$pgrep" = "" ]; then
  log "pgrep utility not found!"
  do_exit 1
fi

uid=`id -u`
pgrep="$pgrep -u $uid -f"

waittime=5

check_proc () {
 local exec_cmd="$1"
 if [ ! -z "`$pgrep "$exec_cmd"`" ]; then
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

if [ ! -f "__HOME/.config/pulse/client.conf" ]; then
 mkdir -p "__HOME/.config/pulse"
 echo "autospawn=no" > "__HOME/.config/pulse/client.conf"
fi

$pulse -k 2>/dev/null
if ! wait_for_proc stopped "$pulse" ; then
 log "pulseaudio server kill failed!"
 do_exit 3
fi

log "purging config files"
rm -fv "__HOME/.config/pulse/default.pa"
rm -fv "__HOME/.config/pulse/daemon.conf"
rm -fv "__HOME/.config/pulse/client.conf"

install -d "__HOME/.config/pulse" 2>/dev/null
socket=`cat "$script_dir/default.pa" | grep "module-native-protocol-unix" | grep "socket" | cut -d" " -f3 | cut -d"=" -f2`
echo "autospawn=no" > "__HOME/.config/pulse/client.conf"
test "z$socket" = "z" || echo "default-server=unix:$socket" >> "__HOME/.config/pulse/client.conf"
install "$script_dir/daemon.conf" "__HOME/.config/pulse/daemon.conf"
install "$script_dir/default.pa" "__HOME/.config/pulse/default.pa"

if [ `check_proc "$pulse"` = "r" ]; then
 log "pulseaudio still working and cannot be stopped!"
 do_exit 1
fi

#try to dump pulseaudio default dlpath
modules_dir=`pulseaudio --dump-conf | grep "^dl-search-path = " | sed "s|^dl-search-path = ||g"`
if [ ! -z "$modules_dir" ]; then
 export PULSE_DLPATH="__BIN/pulse-modules:__HOME/apps/pulse-modules:$modules_dir"
 log "using custom PULSE_DLPATH = $PULSE_DLPATH"
 if [ -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH="__BIN/pulse-modules:__HOME/apps/pulse-modules"
 else
  export LD_LIBRARY_PATH="__BIN/pulse-modules:__HOME/apps/pulse-modules:$LD_LIBRARY_PATH"
 fi
 log "using custom LD_LIBRARY_PATH = $LD_LIBRARY_PATH"
fi

#TODO: configurable pulseaudio logfiles location
#remove old pulseaudio logfiles
rm -fv /tmp/pulse-$uid.log
rm -fv /tmp/pulse-$uid.log.*

$pulse -D -vvvv --log-target=newfile:/tmp/pulse-$uid.log
wait_for_proc started "$pulse"

if [ `check_proc "$pulse"` = "s" ]; then
 log "pulseaudio startup failed!"
 do_exit 1
fi

pax11publish=`which pax11publish 2> /dev/null`
if [ "$pax11publish" != "" ]; then
  log "exporting pulseaudio parameters to x11"
  pax11publish -e
fi

do_exit 0
