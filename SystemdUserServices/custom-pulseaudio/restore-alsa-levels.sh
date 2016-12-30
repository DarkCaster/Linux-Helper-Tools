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

if [ -f "$script_dir/mixer.state" ]; then
 log "Restoring alsa mixer settings"
 /usr/sbin/alsactl -f "$script_dir/mixer.state" store
fi

do_exit 0

