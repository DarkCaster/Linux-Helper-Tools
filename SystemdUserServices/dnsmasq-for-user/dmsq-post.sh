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

check_running () {
 local pid="$1"
 test "`ps -u $thisusername --no-headers | grep \"dnsmasq\" | awk '{print $1}' | grep $pid | wc -l`" -ge 1 && echo "y" || echo "n"
}

for target in /tmp/dnsmasq-user-$thisuser-private-*
do
 pidfile="$target/dnsmasq.pid"
 if [ "`check_running $pidfile`" = "y" ]; then
  log "Skipping running dnsmasq at $target"
 else
  log "Removing dnsmasq's temp files at $target"
  rm -rf "$target"
 fi
done

do_exit 0

