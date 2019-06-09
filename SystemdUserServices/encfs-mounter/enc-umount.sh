#!/bin/sh
#

profile="$1"

#setup config file
config="$HOME/.config/encfs-mounter/mounts.cfg"

#check that config file exists
test ! -f "$config" && echo "config file $HOME/.config/encfs-mounter/mounts.cfg is missing" && exit 1

zenity=""
info=""
error=""

test "z$DISPLAY" != "z" && zenity=`which zenity 2> /dev/null`

if [ "z$zenity" = "z" ]; then
  test "z$DISPLAY" != "z" && zenity=`which yad 2> /dev/null`
  if [ "z$zenity" != "z" ]; then
    info="$zenity --title=Notice --button=OK --escape-ok --text"
    error="$zenity --title=Error --button=OK --escape-ok --text"
    enter="$zenity --title=Password --entry --hide-text"
  else
    info="echo"
    error="echo"
    enter="echo \"\""
  fi
else
info="$zenity --title=Notice --info --text"
error="$zenity --title=Error --error --text"
fi

if [ "z$profile" != "z" ]; then
 while read -r line
 do
  if [ "$(echo "$line" | awk '{print $1}')" = "$profile" ]; then
   encpath=`echo "$line" | awk '{print $2}'`
   decpath=`echo "$line" | awk '{print $3}'`
   flag=`echo "$line" | awk '{print $4}'`
   #check mount
   if [ "$(mount | cut -d " " -f 3 | grep -m 1 "$decpath")" != "" ]; then
    fusermount -u "$decpath"
    res="$?"
    test "z$res" != "z0" && $error "failed to unmount $profile" && exit 2
    if [ "$flag" = "clear" ]; then
     test "$(ls -A "$decpath" | wc -l)" = "0" && rmdir "$decpath"
    fi
	$info "$profile unmounted"
    exit 0
   else
	$error "$profile is not mounted"
    exit 2
   fi
  fi
  false
 done < "$config"
 code="$?"
 test "z$code" != "z0" && $error "Profile $profile is not found" && exit 1
else
 echo "usage: enc-umount.sh <profile name>"
 exit 1 
fi

