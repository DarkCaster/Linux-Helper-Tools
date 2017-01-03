#!/bin/sh
#

encmount=`which enc-mount.sh 2> /dev/null`
test "z$encmount" = "z" && encmount=`which "$HOME/bin/enc-mount.sh" 2> /dev/null`
test "z$encmount" = "z" && echo "enc-mount.sh is missing" && exit 1

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
   echo "attempting to mount automount profile $profile"
   DISPLAY="" "$encmount" $profile "$passwd"
   res="$?"
   test "z$res" != "z0" && echo "failed to mount enc-fs automount $profile" || echo "enc-fs automount profile $profile is mounted" 
done < "$config"
exit 0

