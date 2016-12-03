#!/bin/bash

#install bash lua helper stuff locally into the home directory

script_dir="$( cd "$( dirname "$0" )" && pwd )"

bin_dir="$@"
default_install="no"
test -z "$bin_dir" && echo "installing to home directory: $HOME/apps/wine-launcher" && bin_dir="$HOME/apps/wine-launcher" && default_install="yes"
bin_dir=`realpath $bin_dir`

"$script_dir/../BashLuaHelper/install.sh" "$bin_dir"

mkdir -p "$bin_dir"
cp "$script_dir/wine-build.sh" "$bin_dir"
cp "$script_dir/wine-launcher.sh" "$bin_dir"

if [ "$default_install" = "yes" ]; then
 mkdir -p "$HOME/bin"
 rm -f "$HOME/bin/wine-launcher.sh"
 ln -s "$bin_dir/wine-launcher.sh" "$HOME/bin/wine-launcher.sh"
fi
