#!/bin/bash

#install bash lua helper stuff locally into the home directory

script_dir="$( cd "$( dirname "$0" )" && pwd )"

bin_dir="$@"
default_install="no"
test -z "$bin_dir" && echo "installing to home directory: $HOME/apps/wine-launcher" && bin_dir="$HOME/apps/wine-launcher" && default_install="yes"
bin_dir=`realpath $bin_dir`

"$script_dir/../BashLuaHelper/install.sh" "$bin_dir"

mkdir -p "$bin_dir"

deploy () {
 cp "$@" "$bin_dir"
}

deploy "$script_dir/find-lua-helper.bash.in"
deploy "$script_dir/build.pre.lua"
deploy "$script_dir/build.post.lua"
deploy "$script_dir/wine-build.cfg.lua"
deploy "$script_dir/wine-build.sh"
deploy "$script_dir/wine-launcher.sh"
deploy "$script_dir/launcher.pre.lua"
deploy "$script_dir/launcher.post.lua"
deploy "$script_dir/winemenubuilder.exe"
deploy "$script_dir/desktop-file-creator.sh"

if [ "$default_install" = "yes" ]; then
 mkdir -p "$HOME/bin"
 rm -f "$HOME/bin/wine-launcher.sh"
 ln -s "$bin_dir/wine-launcher.sh" "$HOME/bin/wine-launcher.sh"
fi

if [ -d "$script_dir/extra" ]; then
 cp -rf "$script_dir/extra" "$bin_dir"
fi

