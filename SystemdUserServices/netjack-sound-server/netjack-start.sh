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
jack_wait=`which jack_wait 2> /dev/null`

if [ `check_proc "$jackd"` == "r" ]; then
 log "netJack server already started!"
 do_exit 0
fi

log "Starting netJack server"

$jackd -d netone -l 19000 -n0 -e1 &

wait_for_proc started "$jackd"
if [ -n "$try" ] ; then
 log "netJack server startup failed!"
 do_exit 1
fi

log "waiting for jack startup to finish"
$jack_wait -t $waittime -w 2>/dev/null

do_exit 0

