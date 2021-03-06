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

$pulse -k 2> /dev/null

wait_for_proc stopped $pulse

if [ `check_proc "$pulse"` = "r" ]; then
 log "pulseaudio still working!"
 do_exit 1
fi

rm "__HOME/.config/pulse/daemon.conf"
rm "__HOME/.config/pulse/default.pa"

do_exit 0

