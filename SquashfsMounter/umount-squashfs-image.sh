#!/bin/bash
#

image="$1"
target="$2"

losetup="/usr/sbin/losetup"
test ! -x $losetup && echo "losetup is not available!" && exit 1

test "z$image" = "z" && echo "usage: <image> [symlink-target]" && exit 1

log () {
	local msg="$@"
	logger -t squashfs-mounter-umount -i "$msg"
	echo "$msg"
}

#get full image path
image=`realpath "$image"`
log "trying to umount squashfs image: $image"

#check image is exist
check=`$losetup -j "$image" | wc -l`
test "z$check" = "z0" && log "image at $image not connected!" && exit 1

while read line
do
	device=`echo $line | sed -n 's|\(^/dev/loop[0-9]*\)\(:\s\[.*\]:.*(\)\(.*)$\)|\1|p'`
	test "z$device" = "z" && continue
	log "trying to unmount device: $device"
	udisksctl unmount -b "$device"
	test "$?" != "0" && log "failed to unmount $device"
done < <($losetup -j "$image")

#cleanup stale symlink
test "z$target" = "z" && log "target symlink is not set, exiting now" && exit 0
test -e "$target" && log "error: $target is not a symlink, or this symlink still points to mounted image!" && exit 1
test -L "$target" && log "removing stale symlink at $target" && rm "$target"

exit 0

