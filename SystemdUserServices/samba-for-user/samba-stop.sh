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

smbd=""
smbd_test="`which smbd 2>/dev/null`"

if [ "zzz$smbd_test" = "zzz" ]; then
  log "Trying smbd binary at /usr/sbin/smbd"
  smbd="`which /usr/sbin/smbd 2>/dev/null`"
else
  smbd="$smbd_test"
fi

if [ "zzz$smbd" = "zzz" ]; then
  log "smbd binary is not found!"
  do_exit 9;
fi

thisuser=`id -u`
thisusername=`whoami`

check_pid () {
 local pid_file="$1"
 local cmd="$2"
 if [ ! -f "$pid_file" ]; then
  echo "s"
 else
  pid="`2>/dev/null head -1 \"$pid_file\"`"
  if [ "z$pid" = "z" ]; then
   echo "s"
  else
   check="`ps -u $thisusername -o pid --no-headers | awk '{print $1}' | grep -Fx \"$pid\" | wc -l`"
   if [ "z$check" = "z0" ]; then
    echo "s"
   else
    if [ "z$check" = "z1" ]; then
     check="`cat /proc/$pid/cmdline 2>/dev/null | cut -f1 -d ''`"
     if [ "z$check" = "z$cmd" ]; then
      echo "r"
     else
      echo "s"
     fi
    else
     echo "error"
    fi
   fi
  fi
 fi
}

workdir="/tmp/samba-service-for-$thisuser"
pidfile="$workdir/pids/smbd.pid"

#check if we already started
if [ "`check_pid "$pidfile" "$smbd"`" = "r" ]; then
 log "Stopping samba service at $workdir"
 pid="`cat $pidfile 2>/dev/null`"
 log "Terminating smbd with pid $pid"
 kill -s TERM $pid
 timer="10"
 while [ "`check_pid "$pidfile" "$smbd"`" = "r" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
 test "`check_pid "$pidfile" "$smbd"`" = "r" && ( log "Killing $pid" &&  kill -s KILL $pid )
 timer="5"
 while [ "`check_pid "$pidfile" "$smbd"`" = "r" ] && [ "$timer" -gt 0 ]; do sleep 1; timer=$((timer-1)); done;
 test "`check_pid "$pidfile" "$smbd"`" = "r" && log "Failed to terminate smbd with pid $pid" || log "Process smbd with $pid is terminated"
fi

if [ "`check_pid "$pidfile" "$smbd"`" = "s" ]; then
 log "Removing samba's temp files at $workdir"
 rm -rf "$workdir"
fi

do_exit 0

