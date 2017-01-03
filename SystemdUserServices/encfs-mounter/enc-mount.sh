#!/bin/sh
#

profile="$1"
input_passwd="$2"

#setup config file
config="$HOME/.config/encfs-mounter/mounts.cfg"

#check that config file exists
test ! -f "$config" && echo "config file $HOME/.config/encfs-mounter/mounts.cfg is missing" && exit 1

zenity=""
info=""
error=""
enter=""

test "z$DISPLAY" != "z" && zenity=`which zenity 2> /dev/null`

if [ "z$zenity" = "z" ]; then
info="echo"
error="echo"
enter="echo \"\""
else
info="$zenity --title=Notice --info --text"
error="$zenity --title=Error --error --text"
enter="$zenity --title=Password --entry --hide-text --text=Password"
fi

if [ "z$profile" != "z" ]; then
 while read -r line
 do
  if [ "$(echo "$line" | awk '{print $1}')" = "$profile" ]; then
   encpath=`echo "$line" | awk '{print $2}'`
   decpath=`echo "$line" | awk '{print $3}'`
   flag=`echo "$line" | awk '{print $4}'`
   passwd=`echo "$line" | awk '{print $5}'`
   #password from cmdline
   test "z$passwd" = "z" && passwd="$input_passwd"
   #check mount
   if [ "$(mount | cut -d " " -f 3 | grep -m 1 "$decpath")" != "" ]; then
    $info "$profile already mounted"
    exit 2
   else
    #prepare for mount
    test ! -d "$decpath" && mkdir -p "$decpath"
    #cheking if destdir is empty?
    if [ "$flag" = "clear" ]; then 
     test "$(ls -A "$decpath" | wc -l)" != "0" && $error "Mount point $decpath is not empty!" && exit 3
    fi
    #enter password
    test "z$passwd" = "z" && passwd=`$enter`
    #mount
    if [ "z$passwd" != "z" ]; then
     echo "$passwd" | encfs -S "$encpath" "$decpath" -- -o nonempty -o auto_unmount
    else
     encfs "$encpath" "$decpath" -- -o nonempty
    fi
    res="$?"
    test "z$res" != "z0" && $error "Failed to mount $profile" && exit 2
    exit 0
   fi
  fi
  false
 done < "$config"
 code="$?"
 test "z$code" != "z0" && $error "Profile $profile is not found" && exit 1
else
 echo "usage: enc-mount.sh <profile name> [password]"
 exit 1 
fi

