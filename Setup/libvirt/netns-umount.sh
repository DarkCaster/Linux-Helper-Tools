#!/bin/bash

umount_timeout="20"

echo_stderr () {
  1>&2 echo "$@"
}

# manually remove all network namespaces, if any
ip netns list | while read -r netns
do
  echo "removing $netns network namespace"
  ip netns del "$netns" || echo_stderr "failed to remove $netns namespace"
done

umount_mp ()
{
  local mp="$1"
  local ec="0"
  echo "trying to umount $mp"
  local timeleft="$umount_timeout"
  while [[ $timeleft != 0 ]]
  do
    2>/dev/null umount -R $mp
    ec="$?"
    [[ $ec = 0 ]] && return
    [[ $ec = 1 ]] && echo_stderr "cannot umount $mp" && return
    if [[ $ec = 32 ]]; then
      echo "failed to umount $mp, retrying in 1 second"
      sleep 1
      (( timeleft -= 1 ))
      continue
    fi
    echo_stderr "umount error code $ec handling is not implemented"
    return
  done
}

# umount /run/netns
findmnt -U -n -r "/run/netns" | while read -r mnt line_end
do
  [[ -z $mnt ]] && continue
  umount_mp "$mnt"
done
