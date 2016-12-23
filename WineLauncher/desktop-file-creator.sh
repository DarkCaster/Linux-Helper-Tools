#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
test ! -e "$script_dir/$self" && echo "script_dir detection failed. cannot proceed!" && exit 1
script_file=`readlink "$script_dir/$self"`
test ! -z "$script_file" && script_dir=`realpath \`dirname "$script_file"\``

config="$1"
test -z "$config" && echo "usage: desktop-file-creator.sh <config file> <exec profile> [true, to create separate wine startmenu category]" && exit 1
config=`realpath "$config"`
test ! -f "$config" && echo "config file missing" && exit 1
shift 1

profile="$1"
test -z "$profile" && echo "usage: desktop-file-creator.sh <config file> <exec profile> [true, to create separate wine startmenu category]" && exit 1
shift 1

create_cat="$1"
test -z "$create_cat" && create_cat="false"
shift $#

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e prefix -e profile -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -o "$script_dir"

test "${#cfg[@]}" = "0" && echo "can't find variable with bash_lua_helper results. bash_lua_helper failed!" && exit 1

if ! check_lua_export profile.desktop.name; then
 echo "desktop sub-table for selected profile is missing"
 exit 1
fi

tmp_dir=`mktemp -d -t desktop-file-creator-XXXXXXXX`
tmp_desktop="$tmp_dir/${cfg[profile.desktop.filename]}"

# create desktop file
echo "#!/usr/bin/env xdg-open" >> "$tmp_desktop"
echo "[Desktop Entry]" >> "$tmp_desktop"
echo "Type=Application" >> "$tmp_desktop"
echo "Name=${cfg[profile.desktop.name]}" >> "$tmp_desktop"
echo "GenericName=wine-launcher.sh \"$config\" \"$profile\"" >> "$tmp_desktop"
echo "Comment=${cfg[profile.desktop.comment]}" >> "$tmp_desktop"
echo "Exec=wine-launcher.sh \"$config\" \"$profile\" %u" >> "$tmp_desktop"
echo "Icon=${cfg[profile.desktop.icon]}" >> "$tmp_desktop"
if [ "$create_cat" = "true" ]; then
 echo "Categories=Wine;${cfg[profile.desktop.categories]}" >> "$tmp_desktop"
else
 echo "Categories=${cfg[profile.desktop.categories]}" >> "$tmp_desktop"
fi
if [ ! -z "${cfg[profile.desktop.mimetype]}" ]; then
 echo "MimeType=${cfg[profile.desktop.mimetype]}" >> "$tmp_desktop"
fi
echo "Terminal=${cfg[profile.desktop.terminal]}" >> "$tmp_desktop"
echo "StartupNotify=${cfg[profile.desktop.startupnotify]}" >> "$tmp_desktop"
chmod 755 "$tmp_desktop"

###################################
if [ "$create_cat" = "true" ]; then

#create and install directory file
tmp_dirfile="$tmp_dir/wineapps.directory"
echo "#!/usr/bin/env xdg-open" >> "$tmp_dirfile"
echo "[Desktop Entry]" >> "$tmp_dirfile"
echo "Version=1.0" >> "$tmp_dirfile"
echo "Type=Directory" >> "$tmp_dirfile"
echo "Name=Wine Applications" >> "$tmp_dirfile"
echo "Icon=wine" >> "$tmp_dirfile"

mkdir -p "$HOME/.local/share/desktop-directories"
mv "$tmp_dirfile" "$HOME/.local/share/desktop-directories"

#create and install menu file
tmp_menufile="$tmp_dir/wineapps.menu"
cat << EOF > "$tmp_menufile"
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
    "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
	<Name>Applications</Name>
	<Menu>
		<Name>Wine Applications</Name>
		<Directory>wineapps.directory</Directory>
		<Include>
			<Category>Wine</Category>
		</Include>
	</Menu>
</Menu>
EOF

mkdir -p "$HOME/.config/menus/applications-merged"
test ! -e "$HOME/.config/menus/mate-applications-merged" && ln -s applications-merged "$HOME/.config/menus/mate-applications-merged"
cp "$tmp_menufile" "$HOME/.config/menus/applications-merged"
mv "$tmp_menufile" "$HOME/.config/menus/mate-applications-merged"

fi
###################################

mkdir -p "$HOME/.local/share/applications"
mv "$tmp_desktop" "$HOME/.local/share/applications"

rm -rf "$tmp_dir"
