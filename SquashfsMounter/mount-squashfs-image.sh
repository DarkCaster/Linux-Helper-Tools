#!/bin/sh
#

#TODO: change to other udisks frontend such as udiskie

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
log "trying to mount squashfs image: $image"

#check image is exist
check=`$losetup -j "$image" | wc -l`
[ "$check" = "1" ] && log "image at $image already connected!" && exit_with_lock 1

#check link validity
if [ ! -z "$target" ]; then
	[ -e "$target" ] && log "error: $target is not a symlink, or this symlink point to already mounted image!" && exit_with_lock 1
	[ -L "$target" ] && log "removing incorrect symlink at $target" && rm "$target"
fi

#connect loop device
udisks_output=`"$udisksctl" loop-setup --no-user-interaction -r -f "$image"`
[ "$?" != "0" ] && log "last operation failed with output: $udisks_output" && exit_with_lock 1

device=`echo "$udisks_output" | grep -oE '( )(\/dev\/loop)([0-9]*)' | tr -d '[:blank:]'`
[ "$?" != "0" ] && log "device detection regexp failed!" && exit_with_lock 1
[ ! -b "$device" ] && log "error: device $device is not a /dev/loop block device" && exit_with_lock 1
log "awaiting udisks daemon to finalize mount loop device: $device"

#check automount
automount="false"

#TODO: automount check for other DE
if [ "$XDG_SESSION_DESKTOP" = "MATE" ]; then
 automount=`gsettings get org.mate.media-handling automount`
elif [ "$XDG_SESSION_DESKTOP" = "KDE" ]; then
 automount="false"
fi

if [ "$automount" != "true" ]; then
 log "automount is disabled for your DE, trying to manually mount device $device"
 "$udisksctl" mount --no-user-interaction -b "$device"
 [ "$?" != "0" ] && log "mount failed!" && exit_with_lock 1
fi

mounted="false"
counter="10"

while [ $counter -gt 1 ] ; do
  counter=`expr $counter - 1`
  check=`cat /etc/mtab | cut -f1 -d' ' | grep "$device" | wc -l`
  [ "$check" = "1" ] && mounted="true" && break
  sleep 1
done

[ "$mounted" = "false" ] && log "timed out while waiting for $device to mount" && exit_with_lock 1

#TODO: may need fix for other udisks frontends
if [ "$automount" != "true" ]; then
  log "issuing udisksctl loop-delete as autoclear workaround when automount is disabled on $device device"
  "$udisksctl" loop-delete --no-user-interaction -b "$device"
  [ "$?" != "0" ] && log "command failed!" && exit_with_lock 1
fi

[ -z "$target" ] && log "target symlink is not set, exiting now" && exit_with_lock 0

log "creating symlink for device: $device"
mountpoint=`"$udisksctl" info -b "$device" | grep --max-count=1 -E "^( )*MountPoints:" | awk '{print $2}'`
[ ! -d "$mountpoint" ] && log "error: mountpoint $mountpoint directory is not exist!" && exit_with_lock 1

ln -s "$mountpoint" "$target"
[ "$?" != "0" ] && log "failed to create symlink to $mountpoint at $target" && exit_with_lock 1

log "created symlink $target pointing to $mountpoint"
exit_with_lock 0
