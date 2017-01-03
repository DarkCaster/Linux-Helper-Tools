#!/bin/sh
#

encumount=`which enc-umount.sh 2> /dev/null`
test "z$encumount" = "z" && encumount=`which "$HOME/bin/enc-umount.sh" 2> /dev/null`
test "z$encumount" = "z" && echo "enc-umount.sh is missing" && exit 1

#setup config file
config="$HOME/.config/encfs-mounter/mounts.cfg"

#check that config file exists
test ! -f "$config" && echo "config file $HOME/.config/encfs-mounter/mounts.cfg is missing" && exit 0

while read -r line
do
   profile=`echo "$line" | awk '{print $1}'`
   passwd=`echo "$line" | awk '{print $5}'`
   auto=`echo "$line" | awk '{print $6}'`
   #check
   test "z$profile" = "z" && continue
   test "z$passwd" = "z" && continue
   test "z$auto" != "zauto" && continue
   #try mount
   echo "attempting to unmount automount profile $profile"
   DISPLAY="" "$encumount" $profile
   res="$?"
   test "z$res" != "z0" && echo "failed to unmount enc-fs automount $profile" || echo "enc-fs automount profile $profile is unmounted"
done < "$config"
exit 0

