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
 test "`ps -u $thisusername --no-headers | grep \"istgt\" | awk '{print $1}' | grep \"^$pid\$\" | wc -l`" -ge 1 && echo "y" || echo "n"
}

for target in /tmp/istgt-user-$thisuser-private-*
do
if [ -d "$target" ]; then
log "Stopping istgt service at $target"
for pidfile in $target/*.pid
do
  pid="`cat $pidfile 2>/dev/null`"
  if [ "zzz$pid" = "zzz" ] || [ "`echo \"$pid\" | wc -l`" -gt 1 ]; then
    log "Skipping incorrect pid $pidfile"
  else
    if [ "`check_running $pid`" = "y" ]; then
      log "Terminating istgt with pid $pid"
      kill -s INT $pid
      timer="10"
      while [ "`check_running $pid`" = "y" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
      test "`check_running $pid`" = "y" && ( log "Killing $pid" &&  kill -s KILL $pid )
      timer="5"
      while [ "`check_running $pid`" = "y" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
      test "`check_running $pid`" = "y" && log "Failed to terminate istgt with pid $pid" || log "Process istgt with $pid is terminated"
    fi
  fi
done
fi
done

if [ "`ps -u $thisusername --no-headers | grep \"istgt\" | wc -l`" -ge 1 ]; then
  log "There are more istgt processes running, do not attempt to perform cleanup"
  do_exit 0
fi

for target in /tmp/istgt-user-$thisuser-private-*
do
  if [ -d "$target" ]; then
    log "Removing istgt's temp files at $target"
    rm -rf "$target"
  fi
done

