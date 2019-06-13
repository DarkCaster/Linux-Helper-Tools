#!/bin/bash

curdir="$( cd "$( dirname "$0" )" && pwd )"

set -e

target="$1"
[[ -z $target ]] && echo "usage: install.sh <target directory prefix, /usr/local for example>" && exit 1
[[ ! -d $target ]] && echo "target directory is missing" && exit 1

curdir="$( cd "$( dirname "$0" )" && pwd )"

cp "$curdir"/netns-*.sh "$target/bin"
[[ -f /etc/sudoers.d/netns-runner ]] && rm "/etc/sudoers.d/netns-runner"
cp "$curdir/netns-runner.sudoers" "/etc/sudoers.d/99-netns-runner"

"$curdir/update_shebang.sh" "$target/bin/netns-runner.sh"
"$curdir/update_shebang.sh" "$target/bin/netns-exec.sh"

sed -i "s|__prefix__|""$target/bin""|g" "$target/bin/netns-runner.sh"
sed -i "s|__prefix__|""$target/bin""|g" "$target/bin/netns-exec.sh"
sed -i "s|__prefix__|""$target/bin""|g" "/etc/sudoers.d/99-netns-runner"

chmod 755 "$target/bin/netns-runner.sh"
chmod 700 "$target/bin/netns-exec.sh"
chmod 440 "/etc/sudoers.d/99-netns-runner"
