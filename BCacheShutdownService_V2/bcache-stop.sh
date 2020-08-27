#!/bin/bash
#

timeout="60"

echo_stderr () {
  1>&2 echo "$@"
}

wait_for_device ()
{
  local target="$1"
  echo "awaiting for $target device to disappear"
  local timeleft="$timeout"
  while [[ $timeleft != 0 ]]
  do
    [[ ! -e $target ]] && echo "$target device was disabled" && return
    sleep 1
    (( timeleft -= 1 ))
  done
  echo_stderr "$target device was timed out"
}

#send stop-notification to all bcache-cache devices
for target in /sys/fs/bcache/*/stop
do
  [[ $target = "/sys/fs/bcache/*/stop" ]] && continue
  [[ ! -e $target ]] && continue
  echo "triggering $target"
  echo "1" > $target
done

for target in /dev/bcache*
do
  [[ $target = "/dev/bcache*" ]] && continue
  [[ $target = "/dev/bcache" ]] && continue
  wait_for_device "$target"
done
