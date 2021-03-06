#!/bin/bash

obj="$1"
op="$2"
sub="$3"

# silently exit on unsupported operations
[[ $op = attach || $op = reconnect || $op = restore || $op = migrate ]] && exit 0

logfile="/tmp/qemu-hook-debug.log"

debug () {
  local mark=`date "+%Y-%m-%d %H:%M:%S"`
  1>&2 echo "[DEBUG] $@"
  [[ ! -z $logfile ]] && echo "[$mark] $@" >> "$logfile"
  true
}

while read line
do
  [[ $line =~ "<uuid>"([0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+"-"[0-9a-fA-F]+)"</uuid>" ]] && \
    uuid=`echo ${BASH_REMATCH[1]} | tr '[:upper:]' '[:lower:]'` && break
done

[[ -z $uuid ]] && debug "no valid domain UUID was decoded from provided XML file" && exit 0

debug "processing hooks for domain uuid: $uuid, op=$op sub=$sub"

#detection of actual script location, and\or link location
link_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
[[ ! -e $link_dir/$self ]] && debug "script_dir detection failed. cannot proceed!" && exit 1
if [[ -L $link_dir/$self ]]; then
  script_file=`readlink -f "$link_dir/$self"`
  script_dir=`realpath \`dirname "$script_file"\``
else
  script_dir="$link_dir"
fi

#detect hooks_dir
hooks_dir="$link_dir"
[[ -d "$link_dir/hook_manager" ]] && hooks_dir="$link_dir/hook_manager"

#try hook-config
hook_cfg="$hooks_dir/$uuid.cfg.lua"
[[ ! -L $hook_cfg ]] && debug "hook-config for uuid=$uuid is not installed, exiting" && exit 0
hook_cfg=`readlink "$hook_cfg"`
[[ ! -e $hook_cfg ]] && debug "hook-config for uuid=$uuid is a dangling symlink, exiting" && exit 0
hook_cfg_uid=`realpath -s "$hook_cfg" | md5sum -t | cut -f1 -d" "`

#activate some laodables if available
. "$script_dir/loadables-helper.bash.in"
#check for some required commands
. "$script_dir/find-commands.bash.in"

tmp_base_dir="$TMPDIR"
[[ -z $tmp_base_dir || ! -d $tmp_base_dir ]] && tmp_base_dir="/tmp"
tmp_dir=`realpath -m "$tmp_base_dir/qemu-hooks-$hook_cfg_uid"`
if [[ ! -d "$tmp_dir" ]]; then
  mkdir -p "$tmp_dir" || exit 10
  tmp_dir_created="yes"
fi
logfile="$tmp_dir/debug.log"

. "$script_dir/find-lua-helper.bash.in" "$script_dir/BashLuaHelper" "$script_dir/../BashLuaHelper"

. "$bash_lua_helper" "$hook_cfg" -e global_params -e hooks -b "$script_dir/hook-config.pre.lua" -a "$script_dir/hook-config.post.lua" -o "$uuid" -o "$hook_cfg_uid" -o "$script_dir" -o "$tmp_dir"

[[ "${#cfg[@]}" = 0 ]] && debug "can't find config storage variable populated by bash_lua_helper. bash_lua_helper failed!" && exit 1

[[ ${cfg[hooks]} = none ]] && debug "can't find valid hooks sequence for domain uuid: $uuid" && exit 0

#exit after any error
set -e

cur_user=`id -u`
cur_username=`id -un`
cur_group=`id -g`
cur_groupname=`id -gn`

req_user=`getent passwd "${cfg[global_params.user]}" | head -n1 | cut -f3 -d":"`
req_username=`getent passwd "${cfg[global_params.user]}" | head -n1 | cut -f1 -d":"`
req_group=`getent group "${cfg[global_params.group]}" | head -n1 | cut -f3 -d":"`
req_groupname=`getent group "${cfg[global_params.group]}" | head -n1 | cut -f1 -d":"`

[[ -z $req_groupname || -z $req_group ]] && debug "failed to detect required group id or name" && exit 1
[[ -z $req_username || -z $req_user ]] && debug "failed to detect required user id or name" && exit 1

qemu_hook_lock_entered="false"

qemu_hook_lock_enter() {
  local nowait="$1"
  if mkdir "$tmp_dir/qemu-hook.sh.lock" 2>/dev/null; then
    qemu_hook_lock_entered="true"
    return 0
  else
    [[ ! -z $nowait ]] && return 1
    debug "awaiting lock release"
    while ! qemu_hook_lock_enter "nowait"; do
      sleep 0.25
    done
    qemu_hook_lock_entered="true"
    return 0
  fi
}

qemu_hook_lock_exit() {
  if [[ $qemu_hook_lock_entered = true ]]; then
    rmdir "$tmp_dir/qemu-hook.sh.lock" 2>/dev/null || true
    qemu_hook_lock_entered="false"
  fi
  return 0
}

check_pid () {
  local pid_file="$1"
  local bin_path="$2"
  [[ ! -f $pid_file ]] && return 1
  local pid=`cat "$pid_file"`
  [[ ! -d /proc/$pid ]] && return 1
  [[ ! -z $bin_path && `( 2>/dev/null cat "/proc/$pid/cmdline" || true ) | cut -f1 -d ''` != $bin_path ]] && return 1
  return 0
}

wait_for_pid_created () {
  local pid_file="$1"
  local bin_path="$2"
  local timeout="$3"
  [[ -z $timeout ]] && timeout="${cfg[global_params.timeout]}"
  local timepass="0"
  local step="0.1"
  while [[ `echo "$timepass<=$timeout" | bc -q` = 1 ]]
  do
    check_pid "$pid_file" "$bin_path" && break
    [[ `echo "$timepass>=1.0" | bc -q` = 1 ]] && step="0.25"
    [[ `echo "$timepass>=3.0" | bc -q` = 1 ]] && step="0.5"
    [[ `echo "$timepass>=7.0" | bc -q` = 1 ]] && step="1"
    sleep $step
    timepass=`echo "$timepass+$step" | bc -q`
  done
  [[ `echo "$timepass>$timeout" | bc -q` = 1 ]] && return 1
  return 0
}

wait_for_pid_removed () {
  local pid_file="$1"
  local bin_path="$2"
  local timeout="$3"
  [[ -z $timeout ]] && timeout="${cfg[global_params.timeout]}"
  local timepass="0"
  local step="0.1"
  while [[ `echo "$timepass<=$timeout" | bc -q` = 1 ]]
  do
    check_pid "$pid_file" "$bin_path" || break
    [[ `echo "$timepass>=1.0" | bc -q` = 1 ]] && step="0.25"
    [[ `echo "$timepass>=3.0" | bc -q` = 1 ]] && step="0.5"
    [[ `echo "$timepass>=7.0" | bc -q` = 1 ]] && step="1"
    sleep $step
    timepass=`echo "$timepass+$step" | bc -q`
  done
  [[ `echo "$timepass>$timeout" | bc -q` = 1 ]] && return 1
  return 0
}

add_hook_dep () {
  local id="$1"
  mkdir -p "$tmp_dir/$id"
  touch "$tmp_dir/$id/$uuid"
}

remove_hook_dep () {
  local id="$1"
  mkdir -p "$tmp_dir/$id"
  rm -f "$tmp_dir/$id/$uuid"
}

check_hook_dep () {
  local id="$1"
  mkdir -p "$tmp_dir/$id"
  [[ -z `ls -1 "$tmp_dir/$id"` ]] && return 0
  return 1
}

qemu_hook_lock_enter

trap qemu_hook_lock_exit EXIT INT QUIT TERM

# add access to tmp_dir to requested user
if [[ $tmp_dir_created = yes ]]; then
  setfacl -m "u:$req_user:rwx" "$tmp_dir"
  setfacl -dm "u:$req_user:rwx" "$tmp_dir"
  setfacl -m "g:$req_group:rwx" "$tmp_dir"
  setfacl -dm "g:$req_group:rwx" "$tmp_dir"
fi

# create symlinks to TMPDIR, to simplify access to temp-directory from outside world (knowing only domain uuid)
hook_min=`get_lua_table_start hooks`
hook_max=`get_lua_table_end hooks`
for ((hook_cnt=hook_min;hook_cnt<hook_max;++hook_cnt))
do
  if [[ ! -L $tmp_base_dir/qemu-hooks-$uuid || `readlink "$tmp_base_dir/qemu-hooks-$uuid"` != "$tmp_dir" ]]; then
    rm -f "$tmp_base_dir/qemu-hooks-$uuid"
    ln -s "$tmp_dir" "$tmp_base_dir/qemu-hooks-$uuid"
  fi
done

for ((hook_cnt=hook_min;hook_cnt<hook_max;++hook_cnt))
do
  hook_start="$script_dir/${cfg[hooks.$hook_cnt.type]}-start.bash.in"
  if [[ $op = ${cfg[hooks.$hook_cnt.op_start]} ]]; then
    # check hook with this ID is not already activated by other domain
    if check_hook_dep "${cfg[hooks.$hook_cnt.id]}"; then
      # launch hook start-script only if not already activated by other domain
      [[ ! -f $hook_start ]] && debug "hook start script not found at $hook_start" && exit 1
      debug "running $hook_start for domain $uuid"
      . "$hook_start"
    fi
    # launch add_dep function that will state hook with this ID as activated by current domain
    add_hook_dep "${cfg[hooks.$hook_cnt.id]}"
  fi
done

for ((hook_cnt=hook_max-1;hook_cnt>=hook_min;--hook_cnt))
do
  hook_stop="$script_dir/${cfg[hooks.$hook_cnt.type]}-stop.bash.in"
  if [[ $op = ${cfg[hooks.$hook_cnt.op_stop]} ]]; then
    # launch remove_dep function that will state hook with this ID has been released by current domain
    remove_hook_dep "${cfg[hooks.$hook_cnt.id]}"
    # check, that we have no references on this hook
    if check_hook_dep "${cfg[hooks.$hook_cnt.id]}"; then
      # launch hook stop-script if activated only by this domain
      [[ ! -f $hook_stop ]] && debug "hook stop script not found at $hook_stop" && exit 1
      debug "running $hook_stop for domain $uuid"
      . "$hook_stop"
    fi
  fi
done
