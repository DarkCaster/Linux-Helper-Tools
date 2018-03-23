#!/bin/bash

#detection of actual script location
curdir="$PWD"
script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $script_dir/$self ]] && echo "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $script_dir/$self ]]; then
  script_file=`readlink -f "$script_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
fi

show_usage() {
  echo "usage: libvirt-launcher-desktop-file-creator.sh <config file> <profile> <action: install\uninstall>"
  exit 1
}

#load parameters
config="$1"
[[ -z $config ]] && show_usage
shift 1

profile="$1"
[[ -z $profile ]] && show_usage
shift 1

action="$1"
[[ $action != install && $action != uninstall ]] && show_usage
shift 1

debug () {
  true
}

#activate some laodables if available
. "$script_dir/loadables-helper.bash.in"
#check for some required commands
. "$script_dir/find-commands.bash.in"

#generate uid for given config file
[[ ! -e $config ]] && echo "config file not found: $config" && exit 1
config=`realpath -s "$config"`
config_uid=`echo "$config" | md5sum -t | cut -f1 -d" "`

#temp directory
tmp_dir="$TMPDIR"
[[ -z $tmp_dir || ! -d $tmp_dir ]] && tmp_dir="/tmp"
ctl_dir="$tmp_dir/libvirt-launcher-$config_uid"
mkdir -p "$ctl_dir"

. "$script_dir/find-lua-helper.bash.in" "$script_dir/BashLuaHelper" "$script_dir/../BashLuaHelper"

. "$bash_lua_helper" "$config" -e global_params -e actions -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -o "$HOME" -o "$script_dir" -o "$curdir" -o "$config_uid" -o "$tmp_dir" -o "$tmp_dir/libvirt-launcher-$config_uid" -x "$@"

if [[ $action = install ]]; then
  echo "creating 'Virtual Machines' submenu and category"

  #create and install directory file
  tmp_dirfile="$tmp_dir/libvirt-launcher.directory"
  echo "#!/usr/bin/env xdg-open" >> "$tmp_dirfile"
  echo "[Desktop Entry]" >> "$tmp_dirfile"
  echo "Version=1.0" >> "$tmp_dirfile"
  echo "Type=Directory" >> "$tmp_dirfile"
  echo "Name=Virtual Machines" >> "$tmp_dirfile"
  echo "Icon=computer" >> "$tmp_dirfile"
  mkdir -p "$HOME/.local/share/desktop-directories"
  mv "$tmp_dirfile" "$HOME/.local/share/desktop-directories"

  #create and install menu file
  tmp_menufile="$tmp_dir/libvirt-launcher.menu"
  echo "<!DOCTYPE Menu PUBLIC \"-//freedesktop//DTD Menu 1.0//EN\" \"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd\">" > "$tmp_menufile"
  echo "<Menu>" >> "$tmp_menufile"
  echo "<Name>Applications</Name>" >> "$tmp_menufile"
  echo "<Menu>" >> "$tmp_menufile"
  echo "<Name>Virtual Machines</Name>" >> "$tmp_menufile"
  echo "<Directory>libvirt-launcher.directory</Directory>" >> "$tmp_menufile"
  echo "<Include>" >> "$tmp_menufile"
  echo "<Category>vm</Category>" >> "$tmp_menufile"
  echo "</Include>" >> "$tmp_menufile"
  echo "</Menu>" >> "$tmp_menufile"
  echo "</Menu>" >> "$tmp_menufile"

  #TODO: for now only generic and mate applications-merged menus supported, add other DE support if needed
  mkdir -p "$HOME/.config/menus/applications-merged"
  test ! -e "$HOME/.config/menus/mate-applications-merged" && ln -s applications-merged "$HOME/.config/menus/mate-applications-merged"
  cp "$tmp_menufile" "$HOME/.config/menus/applications-merged"
  mv "$tmp_menufile" "$HOME/.config/menus/mate-applications-merged"
fi

if check_lua_export actions.desktop_file.name; then
  desktop_file="$config_uid-$profile.desktop"
  tmp_desktop="$tmp_dir/$desktop_file"
  if [[ $action = install ]]; then
    echo "creating desktop file for profile $profile"
    # create desktop file
    echo "#!/usr/bin/env xdg-open" >> "$tmp_desktop"
    echo "[Desktop Entry]" >> "$tmp_desktop"
    echo "Type=Application" >> "$tmp_desktop"
    echo "Name=${cfg[actions.desktop_file.name]}" >> "$tmp_desktop"
    echo "GenericName=${cfg[actions.desktop_file.name]}" >> "$tmp_desktop"
    echo "Comment=${cfg[actions.desktop_file.comment]}" >> "$tmp_desktop"
    echo "Exec=$script_dir/libvirt-launcher.sh \"$config\" \"$profile\"" >> "$tmp_desktop"
    echo "Icon=${cfg[actions.desktop_file.icon]}" >> "$tmp_desktop"
    echo "Categories=vm;" >> "$tmp_desktop"
    echo "Terminal=false" >> "$tmp_desktop"
    echo "StartupNotify=false" >> "$tmp_desktop"
    chmod 755 "$tmp_desktop"
    [[ -e $HOME/.local/share/applications/$desktop_file ]] && rm "$HOME/.local/share/applications/$desktop_file"
    mkdir -p "$HOME/.local/share/applications"
    mv "$tmp_desktop" "$HOME/.local/share/applications/$desktop_file"
  else
    echo "removing desktop file for profile $profile"
    rm "$HOME/.local/share/applications/$desktop_file"
  fi
fi

echo "running update-desktop-database"
update-desktop-database "$HOME/.local/share/applications"
