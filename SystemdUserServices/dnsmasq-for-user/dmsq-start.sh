#!/bin/sh
#

extlog=""

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
authbind=""

if [ "zzz$thisuser" != "zzz0" ]; then
  authbind="`which authbind 2>/dev/null`"
  if [ "zzz$authbind" = "zzz" ]; then
    log "authbind binary is required to run dnsmasq server for regular user account!"
    do_exit 10
  fi
fi

dnsmasq=""
dnsmasq_test="`which dnsmasq 2>/dev/null`"

if [ "zzz$dnsmasq_test" = "zzz" ]; then
  log "Trying dnsmasq binary at /usr/sbin/dnsmasq"
  dnsmasq="`which /usr/sbin/dnsmasq 2>/dev/null`"
else
  dnsmasq="$dnsmasq_test"
fi

if [ "zzz$dnsmasq" = "zzz" ]; then
  log "dnsmasq binary is not found!"
  do_exit 9;
fi

shares_in=""

showusage () {
 echo "Usage: dnsmasq-start.sh <config.in>"
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

eval "shares_in=\"\${$OPTIND}\""

if [ "zzz$shares_in" = "zzz" ] || [ ! -f "$shares_in" ]; then
 log "config.in file with user addons is not set or not exists!"
 showusage
 do_exit 4
fi
}

parseopts "$@"

#check if we already started
if [ "`ps --no-headers -u $thisuser | grep dnsmasq | wc -l`" -gt 0 ]; then
  log "dnsmasq is already running for this user! exiting."
  do_exit 3
fi

workdir="`mktemp -d -t dnsmasq-user-$thisuser-private-XXXXXX`"
extlog="$workdir/starter-script.log"

if [ "zzz$workdir" = "zzz" ]; then
  log "Failed to create workdir!"
  do_exit 2
fi

log "dnsmasq's workdir is set to: $workdir"

pidfile="$workdir/dnsmasq.pid"
logfile="$workdir/dnsmasq.log"

config_final="$workdir/config.final"
config_auto="$workdir/config.auto"

echo "dhcp-leasefile=\"$workdir/dnsmasq.leases\"" > "$config_auto"
echo "log-queries" >> "$config_auto"
echo "log-dhcp" >> "$config_auto"

cat "$config_auto" "$shares_in" > "$config_final"

if [ "zzz$authbind" = "zzz" ]; then
 log "Starting dnsmasq daemon"
 "$dnsmasq" --conf-file="$config_final" --pid-file="$pidfile" --log-facility="$logfile" --log-dhcp
 test "z$?" != "z0" && do_exit 1
else
 log "Starting dnsmasq daemon with authbind"
 "$authbind" --deep "$dnsmasq" --conf-file="$config_final" --pid-file="$pidfile" --log-facility="$logfile" --log-dhcp
 test "z$?" != "z0" && do_exit 1
fi

do_exit 0

