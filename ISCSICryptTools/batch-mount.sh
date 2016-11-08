#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

config="$1"
usezenity="$2"

"$script_dir/iscsi-connect.sh" "$config" "$usezenity"
test "$?" != "0" && exit 1

"$script_dir/luks-mount.sh" "$config" "$usezenity"
test "$?" != "0" && exit 1

