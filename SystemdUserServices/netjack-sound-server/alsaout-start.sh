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

. "$script_dir/alsaout-config"
. "$script_dir/service-funcs"


#set base files and directories names
jackd=`which jackd 2> /dev/null`
jackconnect=`which jack_connect 2> /dev/null`
alsaout=`which alsa_out 2> /dev/null`

if [ `check_proc "$jackd"` != "r" ]; then
 log "netJack server not started!"
 do_exit 5
fi

if [ `check_proc "$alsaout"` == "r" ]; then
 log "alsa_out client already started!"
 do_exit 4
fi

log "Starting alsa_out jack client"

$alsaout -d hw:PCH -r 48000 -p$plen -n$pnum &

wait_for_proc started "$alsaout"
if [ -n "$try" ] ; then
 log "alsa_out client startup failed!"
 do_exit 3
fi

try_jackconnect ()
{
 local source="$1"
 local target="$2"
 $jackconnect $source $target >/dev/null 2>&1
 local code="$?"
 echo "$code"
}

code="1"
counter="$waittime"

while test $counter -gt 1 ; do
	counter=`expr $counter - 1`
	code=`try_jackconnect "alsa_out:playback_1" "system:capture_1"`
	test "z$code" = "z0" && break
	sleep 1
done

if [ "z$code" != "z0" ]; then
 log "jackconnect failed!"
 do_exit 2
fi

code="1"
counter="$waittime"

while test $counter -gt 1 ; do
	counter=`expr $counter - 1`
	code=`try_jackconnect "alsa_out:playback_2" "system:capture_2"`
	test "z$code" = "z0" && break
	sleep 1
done

if [ "z$code" != "z0" ]; then
 log "jackconnect failed!"
 do_exit 1
fi

do_exit 0

