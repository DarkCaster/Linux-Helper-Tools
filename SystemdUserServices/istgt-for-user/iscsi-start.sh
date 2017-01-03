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

thisuser=`id -u`
thisusername=`whoami`

istgt=""
istgt_test="`which istgt 2>/dev/null`"

if [ "zzz$istgt_test" = "zzz" ]; then
  log "Trying istgt binary at /usr/sbin/istgt"
  istgt="`which /usr/sbin/istgt 2>/dev/null`"
else
  istgt="$istgt_test"
fi

if [ "zzz$istgt" = "zzz" ]; then
  log "istgt binary is not found!"
  do_exit 10
fi

shares_in=""

showusage () {
 echo "Usage: istgt-start.sh <config>"
 echo "parameters:"
 echo "-h - show help"
}

parseopts () {
 local optname
 while getopts ":h" optname
 do
  case "$optname" in
   "h")
    showusage
    do_exit 9
   ;;
   "?")
    log "Unknown option $OPTARG"
    showusage
    do_exit 8
   ;;
   ":")
    log "No argument given for option $OPTARG"
    showusage
    do_exit 7
   ;;
   *)
    # Should not occur
    log "Unknown error while processing options"
    showusage
    do_exit 6
   ;;
  esac
 done

eval "shares_in=\"\${$OPTIND}\""

if [ "zzz$shares_in" = "zzz" ] || [ ! -f "$shares_in" ]; then
 log "config file is not set or not exists!"
 showusage
 do_exit 5
fi
}

parseopts "$@"

#check if we already started
if [ "`ps --no-headers -u $thisuser | grep istgt | wc -l`" -gt 0 ]; then
  log "istgt is already running for this user! exiting."
  do_exit 4
fi

log "Using config from: $shares_in"

workdir="`mktemp -d -t istgt-user-$thisuser-private-XXXXXX`"

if [ "zzz$workdir" = "zzz" ]; then
  log "Failed to create workdir!"
  do_exit 3
fi

log "istgt's workdir is set to: $workdir"

pidfile="$workdir/istgt.pid"
config_final="$workdir/config.final"

cat "$shares_in" > "$config_final"

log "Starting istgt daemon"
"$istgt" -c "$config_final" -p "$pidfile" > "$workdir/logfile" 2>&1
do_exit 0
