#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

#install cfg helper
"$script_dir/../bash-cfg-helper/install.sh"
if [ "$?" != "0" ]; then
echo "error"
exit 1
fi

#service start and stop scripts
bin_dir="$HOME/apps/stunnel-for-user"
mkdir -p "$bin_dir"

cp "$script_dir/stunnel-start.sh" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/stunnel-start.sh"
chmod 755 "$bin_dir/stunnel-start.sh"

cp "$script_dir/stunnel-stop.sh" "$bin_dir"
sed -i -e "s|__CFGHELPER|$HOME/apps/bash-cfg-helper|g" "$bin_dir/stunnel-stop.sh"
chmod 755 "$bin_dir/stunnel-stop.sh"

