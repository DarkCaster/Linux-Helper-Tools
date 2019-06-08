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

if systemctl is-active --quiet alsa-state.service; then
 log "alsa-state.service is running, will not attempt to restore volumes"
 do_exit 0
fi

if [ -f "$script_dir/mixer.state" ]; then
 log "Restoring alsa mixer settings"
 /usr/sbin/alsactl -f "$script_dir/mixer.state" store
fi

do_exit 0

