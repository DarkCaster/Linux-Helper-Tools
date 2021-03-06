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

check_running () {
 local pid="$1"
 test "`ps -u $thisusername --no-headers | grep \"tftpd\" | awk '{print $1}' | grep \"^$pid\$\" | wc -l`" -ge 1 && echo "y" || echo "n"
}

for target in /tmp/tftpd-user-$thisuser-private-*
do
 pid=`cat "$target/tftpd.pid" 2>/dev/null`
 test -z "$pid" && pid="0"
 if [ "`check_running $pid`" = "y" ]; then
  log "Skipping running tftpd at $target"
 else
  log "Removing tftpd's temp files at $target"
  rm -rf "$target"
 fi
done

do_exit 0

