#!/bin/sh
#

image="$1"
target="$2"

[ -z "$image" ] && echo "usage: <image> [symlink-target]" && exit 1

losetup=`which losetup 2>/dev/null`
[ ! -x "$losetup" ] && echo "losetup is not available!" && exit 1

udisksctl=`which udisksctl 2>/dev/null`
[ ! -x "$udisksctl" ] && echo "udisksctl is not available!" && exit 1

logger=`which logger 2>/dev/null`

log () {
  local msg="$@"
  [ ! -z "$logger" ] && "$logger" -t squashfs-mounter -i "$msg"
  echo "$msg"
}

lock_enter() {
  local nowait="$1"
  if mkdir "/tmp/squashfs-mounter.lock" 2>/dev/null; then
    return 0
  else
    [ ! -z "$nowait" ] && return 1
    log "awaiting lock release"
    while ! lock_enter "nowait"; do
      sleep 1
    done
    return 0
  fi
}

lock_exit() {
  rmdir "/tmp/squashfs-mounter.lock"
}

exit_with_lock(){
  local code="$1"
  lock_exit
  exit $code
}

lock_enter

#get full image path
image=`realpath "$image"`
log "trying to umount squashfs image: $image"

#check image is exist
check=`$losetup -j "$image" | wc -l`
[ "$check" = "0" ] && log "image at $image not connected!" && exit_with_lock 1

"$losetup" -j "$image" | while IFS= read -r line
do
  device=`echo $line | sed -n 's|\(^/dev/loop[0-9]*\)\(:\s\[.*\]:.*(\)\(.*)$\)|\1|p'`
  [ -z "$device" ] && continue
  log "trying to unmount device: $device"
  "$udisksctl" unmount -b "$device"
  [ "$?" != "0" ] && log "failed to unmount $device"
done

#cleanup stale symlink
[ -z "$target" ] && log "target symlink is not set, exiting now" && exit_with_lock 0
[ -e "$target" ] && log "error: $target is not a symlink, or this symlink still points to mounted image!" && exit_with_lock 1
[ -L "$target" ] && log "removing stale symlink at $target" && rm "$target"

exit_with_lock 0
