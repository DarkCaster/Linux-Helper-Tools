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
jackd=`which jackd 2> /dev/null`

if [ `check_proc "$jackd"` == "r" ]; then
 log "Stopping netJack server"
 if [ `term_proc "$jackd"` == "r" ]; then
  log "Grace shutdown failed. Trying to kill."
  if [ `kill_proc "$jackd"` == "r" ]; then
   log "Kill failed!!!"
   do_exit 1
  fi
 fi
else
 log "netJack server is not running."
 do_exit 0
fi

log "netJack server stopped."
do_exit 0

