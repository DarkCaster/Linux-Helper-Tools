#!/bin/bash

# TODO: convert to plain sh use
# (for now, bash is used because it's easy to export and reimport env with it)

cur_username=`id -un`

namespace="$1"
[ -z "$namespace" ] && echo "usage: netns-bg-runner.sh <namespace> <command> [parameters]"
shift 1

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

sudo -- __prefix__/netns-exec.sh bg "$namespace" "$tmp_script" "$@"
