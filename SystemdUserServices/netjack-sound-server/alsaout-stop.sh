#!/bin/bash
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

. "$script_dir/service-funcs"

#set base files and directories names
alsaout=`which alsa_out 2> /dev/null`

if [ `check_proc "$alsaout"` == "r" ]; then
 log "Stopping alsa_out client"
 if [ `term_proc "$alsaout"` == "r" ]; then
  log "Grace shutdown failed. Trying to kill."
  if [ `kill_proc "$alsaout"` == "r" ]; then
   log "Kill failed!!!"
   do_exit 1
  fi
 fi
else
 log "alsa_out client is not running."
 do_exit 0
fi

log "alsa_out client stopped."
do_exit 0

