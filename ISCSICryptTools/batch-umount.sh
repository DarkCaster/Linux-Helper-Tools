#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

config="$1"
usezenity="$2"

export PATH="/usr/sbin:/sbin:$PATH"

"$script_dir/luks-umount.sh" "$config" "$usezenity"
test "$?" != "0" && exit 1

"$script_dir/iscsi-disconnect.sh" "$config" "$usezenity"
test "$?" != "0" && exit 1

test "$usezenity" = "yes" && zenity --info --text="Successfully disconnected ISCSI drive from $config profile"
