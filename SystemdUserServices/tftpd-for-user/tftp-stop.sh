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
if [ -d "$target" ]; then
log "Stopping tftpd service at $target"
for pidfile in $target/*.pid
do
  pid="`cat $pidfile 2>/dev/null`"
  if [ "zzz$pid" = "zzz" ] || [ "`echo \"$pid\" | wc -l`" -gt 1 ]; then
    log "Skipping incorrect pid $pidfile"
  else
    if [ "`check_running $pid`" = "y" ]; then
      log "Terminating tftpd with pid $pid"
      kill -s TERM $pid
      timer="10"
      while [ "`check_running $pid`" = "y" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
      test "`check_running $pid`" = "y" && ( log "Killing $pid" &&  kill -s KILL $pid )
      timer="5"
      while [ "`check_running $pid`" = "y" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
      test "`check_running $pid`" = "y" && log "Failed to terminate tftpd with pid $pid" || log "Process tftpd with $pid is terminated"
    fi
  fi
done
fi
done

if [ "`ps -u $thisusername --no-headers | grep \"atftpd\" | wc -l`" -ge 1 ]; then
  log "There are more tftpd processes running, do not attempt to perform cleanup"
  do_exit 0
fi

for target in /tmp/tftpd-user-$thisuser-private-*
do
  if [ -d "$target" ]; then
    log "Removing tftpd's temp files at $target"
    rm -rf "$target"
  fi
done

do_exit 0
