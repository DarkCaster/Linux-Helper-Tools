#!/bin/bash

# TODO: convert to plain sh syntax
# (for now, bash is used because it's easy to export and reimport env with it)

cur_username=`id -un`

show_usage () {
  echo "usage: netns-runner.sh [-b;-up <pid>;-upf <pid file>] <namespace> <command> [parameters]"
  echo "options:"
  echo "  -b - run command in background"
  echo "  -up <pid> - clone UTS namespace from process with selected PID"
  echo "  -upf <pid file> - clone UTS namespace from process with PID read from selected pid file"
  exit 1
}

is_number () {
  local num="$1"
  [ ! -z "${num##*[!0-9]*}" ] && return 0 || return 1
}

bg="fg"

while true
do
  if [ "$1" == "-b" ]; then
    bg="bg"
  elif [ "$1" == "-up" ]; then
    shift 1
    upid="$1"
    if ! is_number "$upid"; then
      echo "provided pid $upid is not a number"
      exit 1
    fi
  elif [ "$1" == "-upf" ]; then
    shift 1
    upid=`2>/dev/null cat "$1" | head -n1`
    [ -z "$upid" ] && echo "failed to read pid from $1 file" && exit 1
    if ! is_number "$upid"; then
      echo "provided pid $upid is not a number"
      exit 1
    fi
  else
    namespace="$1"
    shift 1
    break
  fi
  shift 1
done

[ -z "$upid" ] && upid="0"
[ -z "$namespace" ] && echo "namespace is empty!" && show_usage
[ "$#" = "0" ] && exit 0

tmp_base_dir="$TMPDIR"
[ ! -d "$tmp_base_dir" ] && tmp_base_dir="/tmp"
[ -z "$tmp_base_dir" ] && tmp_base_dir="/tmp"
mkdir -p "$tmp_base_dir/netns-runner-$cur_username"
chmod 700 "$tmp_base_dir/netns-runner-$cur_username"

tmp_script=`mktemp --tmpdir="$tmp_base_dir/netns-runner-$cur_username" XXXXXXXXXXXX.sh`

echo "#!/bin/bash" > "$tmp_script"
chmod 700 "$tmp_script"

# save environment
export -p >> "$tmp_script"
export -f >> "$tmp_script"
echo "unset SUDO_COMMAND" >> "$tmp_script"
echo "unset SUDO_GID" >> "$tmp_script"
echo "unset SUDO_UID" >> "$tmp_script"
echo "unset SUDO_USER" >> "$tmp_script"
echo "unset USERNAME" >> "$tmp_script"
echo "rm \"$tmp_script\"" >> "$tmp_script"
echo "\"\$@\"" >> "$tmp_script"

sudo -- __prefix__/netns-exec.sh "$bg" "$upid" "$namespace" "$tmp_script" "$@"
