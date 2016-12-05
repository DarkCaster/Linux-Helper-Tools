#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
script_link=`readlink "$script_dir/$0"`
test ! -z "$script_link" && script_dir=`realpath \`dirname "$script_link"\``

config="$1"
test -z "$config" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

profile="$1"
test -z "$profile" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e prefix -e profile -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -o "$script_dir" -x "$@"

log () {
 echo "[ $@ ]"
}

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  log "ERROR: last operation finished with error code $status"
  exit $status
 fi
}

# echo "$cfg_list"

#external wine distribution
if check_lua_export prefix.wine; then
 winedist="${cfg[prefix.wine]}"
 test ! -d "$winedist" && log "directory $winedist is missing" && exit 1
 winedist=`realpath "$winedist"`
 test ! -d "$winedist" && log "directory $winedist is missing" && exit 1
 export WINESERVER="$winedist/bin/wineserver"
 export WINELOADER="$winedist/bin/wine"
 export LD_LIBRARY_PATH="$winedist/lib64:$LD_LIBRARY_PATH"
 export PATH="$winedist/bin:$PATH"
fi

if [ ! -d "${cfg[prefix.root]}" ]; then
 log "creating ${cfg[prefix.root]} root dir for wine prefix"
 mkdir -p "${cfg[prefix.root]}"
 check_errors
fi

wineroot=`realpath "${cfg[prefix.root]}"`
test ! -d "$wineroot" && log "failed to transform ${cfg[prefix.root]} dir with realpath" && exit 1
export WINEPREFIX="$wineroot"

docsdir=""
if check_lua_export prefix.docs; then
 if [ ! -d "${cfg[prefix.docs]}" ]; then
  log "creating ${cfg[prefix.docs]} docs dir"
  mkdir -p "${cfg[prefix.docs]}"
  check_errors
 fi
 docsdir=`realpath "${cfg[prefix.docs]}"`
 test ! -d "$docsdir" && log "failed to transform ${cfg[prefix.docs]} dir with realpath" && exit 1
fi

if check_lua_export prefix.lang; then
 export LANG="${cfg[prefix.lang]}"
 export LC_ALL="${cfg[prefix.lang]}"
fi

if check_lua_export prefix.arch; then
 export WINEARCH="${cfg[prefix.arch]}"
fi

owner="${cfg[prefix.owner]}"
test -z "$owner" && owner="$USER"
org="${cfg[prefix.org]}"
test -z "$org" && org=`uname -n`

#extra preparations. TODO: move to lua config, as optional commands
unset SDL_AUDIODRIVER

create_override() {
 local mode="$1"
 local src="$2"
 local target="$3"
 local name="$4"
 log "creating override: $name"
 if [ ! -z "$src" ] && [ ! -z "$target" ]; then
  cp "$src" "$wineroot/drive_c/windows/system32/$target"
  check_errors
 fi
 local regfile=`mktemp -p "$wineroot/drive_c" --suffix=.reg tmpreg-XXXXXX`
 echo "REGEDIT4" >> "$regfile"
 echo "" >> "$regfile"
 echo "[HKEY_CURRENT_USER\Software\Wine\DllOverrides]" >> "$regfile"
 echo "\"$name\"=\"$mode\"" >> "$regfile"
 regedit "$regfile"
 check_errors
 rm "$regfile"
 check_errors
}

#wineboot, if prefix not initialized
if [ ! -f "$wineroot/launcher.init.mark" ]; then
################################################

touch "$wineroot/launcher.init.mark"
log "performing init for wineprefix in $wineroot"

log "running wineboot"
wineboot
check_errors

for override in ${cfg[prefix.override_list]}
do
 create_override \
 "${cfg[prefix.dll_overrides.$override.1]}" \
 "${cfg[prefix.dll_overrides.$override.2]}" \
 "${cfg[prefix.dll_overrides.$override.3]}" \
 "${cfg[prefix.dll_overrides.$override.4]}"
done

log "setting up owner and organization"
regfile=`mktemp -p "$wineroot/drive_c" --suffix=.reg tmpreg-XXXXXX`
echo "REGEDIT4" >> "$regfile"
echo "" >> "$regfile"
echo "[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion]" >> "$regfile"
echo "\"RegisteredOwner\"=\"$owner\"" >> "$regfile"
echo "\"RegisteredOrganization\"=\"$org\"" >> "$regfile"
echo "" >> "$regfile"
echo "[HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion]" >> "$regfile"
echo "\"RegisteredOwner\"=\"$owner\"" >> "$regfile"
echo "\"RegisteredOrganization\"=\"$org\"" >> "$regfile"
regedit "$regfile"
check_errors
rm "$regfile"
check_errors

################################################
fi

if [ ! -z "$docsdir" ]; then
 log "updating userdata directories"
 pwddir="$PWD"
 cd "$wineroot/drive_c/users/$USER"
 while read line
 do
  link=`readlink -f "$line"`
  link=`realpath "$link"`
  test "$docsdir" = "$link" && continue
  log "processing link: $line"
  rm "$line"
  ln -s "$docsdir" "$line"
 done <<< "$(find * -type l)"
 cd "$pwddir"
 pwddir=""
fi


