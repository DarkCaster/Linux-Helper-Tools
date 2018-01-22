#!/bin/bash

curdir="$( cd "$( dirname "$0" )" && pwd )"

set -e

target="$1"
[[ -z $target ]] && echo "usage: install.sh <target directory prefix, /usr/local for example>" && exit 1
[[ ! -d $target ]] && echo "target directory is missing" && exit 1

curdir="$( cd "$( dirname "$0" )" && pwd )"

cp "$curdir"/netns-*.sh "$target/bin"
cp "$curdir/netns-runner.sudoers" /etc/sudoers.d/

"$curdir/update_shebang.sh" "$target/bin/netns-runner.sh"
"$curdir/update_shebang.sh" "$target/bin/netns-bg-runner.sh"
"$curdir/update_shebang.sh" "$target/bin/netns-exec.sh"

sed -i "s|__prefix__|""$target/bin""|g" "$target/bin/netns-runner.sh"
sed -i "s|__prefix__|""$target/bin""|g" "$target/bin/netns-bg-runner.sh"
sed -i "s|__prefix__|""$target/bin""|g" "$target/bin/netns-exec.sh"
sed -i "s|__prefix__|""$target/bin""|g" "/etc/sudoers.d/netns-runner.sudoers"

chmod 755 "$target/bin/netns-runner.sh"
chmod 755 "$target/bin/netns-bg-runner.sh"
chmod 700 "$target/bin/netns-exec.sh"
chmod 600 "/etc/sudoers.d/netns-runner.sudoers"
