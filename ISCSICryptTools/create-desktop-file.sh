#!/bin/bash

main_script_dir="$( cd "$( dirname "$0" )" && pwd )"

cfgfile="$1"
shift

name="$@"

if [ "z$cfgfile" = "z" ] || [ "z$name" = "z" ]; then
 echo "usage: <config file> <drive label>"
 exit 0
fi

log () {
 local msg="$@"
 echo "$msg"
}

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  log "ERROR: last operation finished with error code $status"
  exit $status
 fi
}

#create desktop folder
mkdir -p "$HOME/.local/share/applications"
check_errors

#load uid
uid=`echo "$cfgfile+$name" | md5sum -t | cut -f1 -d" "`

filename="$HOME/.local/share/applications/iscsi-luks-mount-$uid.desktop"

#create desktop file template
echo "#!/usr/bin/env xdg-open" > "$filename"
echo "" >> "$filename"
echo "[Desktop Entry]" >> "$filename"
echo "Encoding=UTF-8" >> "$filename"
echo "Type=Application" >> "$filename"
echo "Exec=xdg-su -c \"$main_script_dir/batch-mount.sh $cfgfile yes\"" >> "$filename"
echo "Icon=drive-harddisk" >> "$filename"
echo "Name=iscsi-luks mount drive $name" >> "$filename"
echo "Comment=UID $uid" >> "$filename"
echo "Categories=Application;Network;" >> "$filename"
echo "StartupNotify=true" >> "$filename"
echo "Terminal=false" >> "$filename"

chmod 755 "$filename"
check_errors

filename="$HOME/.local/share/applications/iscsi-luks-umount-$uid.desktop"

#create desktop file template
echo "#!/usr/bin/env xdg-open" > "$filename"
echo "" >> "$filename"
echo "[Desktop Entry]" >> "$filename"
echo "Encoding=UTF-8" >> "$filename"
echo "Type=Application" >> "$filename"
echo "Exec=xdg-su -c \"$main_script_dir/batch-umount.sh $cfgfile yes\"" >> "$filename"
echo "Icon=drive-harddisk" >> "$filename"
echo "Name=iscsi-luks umount drive $name" >> "$filename"
echo "Comment=UID $uid" >> "$filename"
echo "Categories=Application;Network;" >> "$filename"
echo "StartupNotify=true" >> "$filename"
echo "Terminal=false" >> "$filename"

chmod 755 "$filename"
check_errors

exit 0

