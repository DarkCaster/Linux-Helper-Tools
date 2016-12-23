#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
test ! -e "$script_dir/$self" && echo "script_dir detection failed. cannot proceed!" && exit 1
script_file=`readlink "$script_dir/$self"`
test ! -z "$script_file" && script_dir=`realpath \`dirname "$script_file"\``

config="$1"
test -z "$config" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

profile="$1"
test -z "$profile" && echo "usage: wine-launcher.sh <config file> <exec profile> [other parameters, will be forwarded to executed apps]" && exit 1
shift 1

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e prefix -e profile -e tweaks -b "$script_dir/launcher.pre.lua" -a "$script_dir/launcher.post.lua" -o "$profile" -o "$script_dir" -x "$@"

shift $#

test "${#cfg[@]}" = "0" && echo "can't find variable with bash_lua_helper results. bash_lua_helper failed!" && exit 1

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
 regedit "$regfile" 2>/dev/null
 check_errors
 rm "$regfile"
 check_errors
}

apply_tweaks() {
 test "${cfg[tweaks.enabled]}" = "false" && return

 #allfonts
 if "${cfg[tweaks.allfonts]}" = "true"; then
  log "applying allfonts tweak"
  "${cfg[tweaks.winetricks]}" allfonts
  check_errors
 fi

 #fontsmooth. idea taken from here: http://www.ubuntugeek.com/ubuntu-tip-easy-way-to-enable-font-smoothing-in-wine.html
 if "${cfg[tweaks.fontsmooth.enabled]}" = "true"; then
  log "applying fontsmooth tweak"
  local regfile=`mktemp -p "$wineroot/drive_c" --suffix=.reg tmpreg-XXXXXX`
  echo "REGEDIT4" >> "$regfile"
  echo "" >> "$regfile"
  echo "[HKEY_CURRENT_USER\Control Panel\Desktop]" >> "$regfile"
  echo "\"FontSmoothing\"=\"${cfg[tweaks.fontsmooth.mode]}\"" >> "$regfile"
  echo "\"FontSmoothingOrientation\"=dword:0000000${cfg[tweaks.fontsmooth.orientation]}" >> "$regfile"
  echo "\"FontSmoothingType\"=dword:0000000${cfg[tweaks.fontsmooth.type]}" >> "$regfile"
  echo "\"FontSmoothingGamma\"=dword:00000578" >> "$regfile"
  regedit "$regfile" 2>/dev/null
  check_errors
  rm "$regfile"
  check_errors
 fi

 true
}

#wineboot, if prefix not initialized
if [ ! -f "$wineroot/launcher.init.mark" ]; then
################################################

touch "$wineroot/launcher.init.mark"
check_errors

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

if check_lua_export prefix.extra_cmd.1; then
 log "executing extra commands"
 pwddir="$PWD"
 cd "${cfg[prefix.extra_cmd.2]}"
 check_errors
 eval "${cfg[prefix.extra_cmd.1]}"
 check_errors
 cd "$pwddir"
 check_errors
fi

log "applying tweaks"
apply_tweaks
test "$profile" = "tweaks" && exit 0

################################################
fi

if [ ! -z "$docsdir" ]; then
 log "updating userdata directories"
 pwddir="$PWD"
 cd "$wineroot/drive_c/users/$USER"
 check_errors
 while read line
 do
  link=`readlink -f "$line"`
  link=`realpath "$link"`
  test "$docsdir" = "$link" && continue
  log "processing link: $line"
  rm "$line"
  check_errors
  ln -s "$docsdir" "$line"
  check_errors
 done <<< "$(find * -type l)"
 cd "$pwddir"
 check_errors
fi

if [ "$profile" = "tweaks" ]; then
 log "re-applying tweaks"
 apply_tweaks
 exit 0
fi

log "running profile $profile"

#cleanup
unset -f create_override
unset -f apply_tweaks
unset pwddir
unset link
unset line
unset docsdir
unset wineroot
unset regfile
unset org
unset owner
unset override
unset winedist
unset bash_lua_helper
unset profile
unset config
unset script_file
unset script_dir
unset self

cd "${cfg[profile.run.2]}"
check_errors
eval "${cfg[profile.run.1]}"

