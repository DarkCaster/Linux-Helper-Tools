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

log "Saving alsa mixer settings"
/usr/sbin/alsactl -f "$script_dir/mixer.state" store

do_exit 0

