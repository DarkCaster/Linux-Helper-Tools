#!/bin/bash
#

# main script for working with configs

script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $script_dir/$self ]] && echo "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $script_dir/$self ]]; then
  script_file=`readlink -f "$script_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
fi

target="$1"
action="$2"
cfgdir="$3"

[[ -z $target || -z $action ]] && echo "usage: libvirt-hook-manager.sh <target hook config file> <action: install/uninstall> [qemu-hook config dir]" && exit 1
[[ $action != install && $action != uninstall ]] && echo "action parameter is incorrect!" && exit 1
[[ -z $cfgdir ]] && cfgdir=`2>/dev/null cat "/etc/qemu-hook-cfgdir"`
[[ -z $cfgdir ]] && cfgdir=`2>/dev/null cat "$script_dir/qemu-hook-cfgdir"`
[[ -z $cfgdir ]] && echo "failed to auto-detect qemu-hook config directory, cannot proceed" && exit 1
[[ ! -f $target ]] && echo "target config is missing!" && exit 1

cfgdir=`realpath -s "$cfgdir"`
hook_cfg_path=`realpath -s "$target"`
hook_cfg_uid=`echo "$hook_cfg_path" | md5sum -t | cut -f1 -d" "`

tmp_dir="$TMPDIR"
[[ -z $tmp_dir || ! -d $tmp_dir ]] && tmp_dir="/tmp"
tmp_dir=`realpath -m "$tmp_dir/qemu-hooks-$hook_cfg_uid"`
mkdir -p "$tmp_dir" || exit 10

. "$script_dir/find-lua-helper.bash.in" "$script_dir/BashLuaHelper" "$script_dir/../BashLuaHelper"

. "$bash_lua_helper" "$hook_cfg_path" -e deps -b "$script_dir/hook-config.pre.lua" -a "$script_dir/hook-config.post.lua" -o "0" -o "$hook_cfg_uid" -o "$script_dir" -o "$tmp_dir"

[[ "${#cfg[@]}" = 0 ]] && echo "can't find config storage variable populated by bash_lua_helper. bash_lua_helper failed!" && exit 1

echo "using config directory at $cfgdir"

deps_min=`get_lua_table_start deps`
deps_max=`get_lua_table_end deps`
for ((deps_cnt=deps_min;deps_cnt<deps_max;++deps_cnt))
do
  uuid="${cfg[deps.$deps_cnt.uuid]}"
  case "$action" in
    "install")
      echo "installing config symlink for $uuid domain"
      2>/dev/null rm -f "$cfgdir/$uuid.cfg.lua"
      ln -s "$hook_cfg_path" "$cfgdir/$uuid.cfg.lua" || echo "failed to create symlink $cfgdir/$uuid.cfg.lua"
    ;;
    *)
      echo "removing config symlink for $uuid domain"
      rm -f "$cfgdir/$uuid.cfg.lua" || echo "failed to remove symlink $cfgdir/$uuid.cfg.lua"
    ;;
  esac
done
