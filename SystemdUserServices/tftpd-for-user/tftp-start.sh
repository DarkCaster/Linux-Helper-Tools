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

tftpd=""
tftpd_test="`which atftpd 2>/dev/null`"

if [ "zzz$tftpd_test" = "zzz" ]; then
  log "Trying tftpd binary at /usr/sbin/tftpd"
  tftpd="`which /usr/sbin/atftpd 2>/dev/null`"
else
  tftpd="$tftpd_test"
fi

if [ "zzz$tftpd" = "zzz" ]; then
  log "tftpd binary is not found!"
  do_exit 9;
fi

options_sh_in=""

showusage () {
 echo "Usage: tftp-start.sh <options.sh.in>"
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
    do_exit 8
   ;;
   "?")
    log "Unknown option $OPTARG"
    showusage
    do_exit 7
   ;;
   ":")
    log "No argument given for option $OPTARG"
    showusage
    do_exit 6
   ;;
   *)
    # Should not occur
    log "Unknown error while processing options"
    showusage
    do_exit 5
   ;;
  esac
 done

eval "options_sh_in=\"\${$OPTIND}\""

if [ "zzz$options_sh_in" = "zzz" ] || [ ! -f "$options_sh_in" ]; then
 log "options.sh.in file with user addons is not set or not exists!"
 showusage
 do_exit 4
fi
}

parseopts "$@"

#check if we already started
if [ "`ps --no-headers -u $thisuser | grep \"atftpd\" | wc -l`" -gt 0 ]; then
  log "tftpd is already running for this user! exiting."
  do_exit 3
fi

workdir="`mktemp -d -t tftpd-user-$thisuser-private-XXXXXX`"

if [ "zzz$workdir" = "zzz" ]; then
  log "Failed to create workdir!"
  do_exit 2
fi

log "tftpd's workdir is set to: $workdir"

pidfile="$workdir/tftpd.pid"
logfile="$workdir/tftpd.log"

. "$options_sh_in"

port="$port"
address="$address"
root_dir="$root_dir"

test -z "$port" && port="69"
test -z "$address" && address="0.0.0.0"
test -z "$root_dir" && log "root_dir not set" && do_exit 1

authbind=""
if [ "$port" -le 1024 ] && [ "z$thisuser" != "z0" ]; then
  authbind="`which authbind 2>/dev/null`"
  if [ "zzz$authbind" = "zzz" ]; then
    log "authbind binary is required to run tftpd server for regular user at ports < 1024"
    do_exit 10
  fi
fi

extra_options="-vvv --daemon --pidfile \"$pidfile\" --user $thisusername --bind-address $address --port $port"

if [ "zzz$authbind" = "zzz" ]; then
  log "Starting tftpd daemon"
  log "startup options: $extra_options \"$root_dir\""
  echo "$extra_options \"$root_dir\"" | xargs "$tftpd"
  test "z$?" != "z0" && log "Startup failed" && do_exit 1
else
  log "Starting tftpd daemon with authbind"
  log "startup options: $extra_options \"$root_dir\""
  echo "$extra_options \"$root_dir\"" | xargs "$authbind" --deep "$tftpd"
  test "z$?" != "z0" && log "Startup failed" && do_exit 1
fi

do_exit 0

