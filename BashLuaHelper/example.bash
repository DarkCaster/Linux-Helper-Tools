#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

# all paths may be relative to current dir
. "$script_dir/lua-helper.bash.in" "$script_dir/example.cfg.lua" -e "config.sub" \
-e "config.paths" -e "config.empty" -b "$script_dir/example.pre.lua" -a "$script_dir/example.post.lua" -o test1 -o test2 -w /tmp
# ^ options at this line is optional ^
