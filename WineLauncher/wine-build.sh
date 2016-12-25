#!/bin/bash

curdir="$PWD"
script_dir="$( cd "$( dirname "$0" )" && pwd )"
self=`basename "$0"`
test ! -e "$script_dir/$self" && echo "script_dir detection failed. cannot proceed!" && exit 1
script_file=`readlink "$script_dir/$self"`
test ! -z "$script_file" && script_dir=`realpath \`dirname "$script_file"\``
test ! -z "$script_file" && self="$script_file" || self="$script_dir/$self"

profile="$1"
test -z "$profile" && echo "usage: wine-build <profile> <install prefix> [alternative wine-build.cfg.lua config file]" && exit 1

prefix="$2"
test -z "$prefix" && echo "usage: wine-build <profile> <install prefix> [alternative wine-build.cfg.lua config file]" && exit 1

config="$3"
test -z "$config" && config="$script_dir/wine-build.cfg.lua"
config=`realpath -s "$config"`

. "$script_dir/find-lua-helper.bash.in"
. "$bash_lua_helper" "$config" -e build -b "$script_dir/build.pre.lua" -a "$script_dir/build.post.lua" -o "$self" -o "$profile" -o "$prefix" -o "$config"

# create tmpdir
tmp_dir=`mktemp -d -t wine-build-XXXXXX`
cd "$tmp_dir"
echo "using temp directory $tmp_dir"

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  echo "ERROR: last operation completed with error code $status"
  cd "$script_dir"
  rm -rf "$tmp_dir"
  exit $status
 fi
}

echo "$cfg_list"

case "${cfg[build.src.type]}" in
 "wget-tarbz")
  echo "downloading source from ${cfg[build.src.link]}"
  wget -O ./source.tar.bz2 "${cfg[build.src.link]}"
  check_errors
  #TODO: check signature
  mkdir "source"
  check_errors
  echo "extracting source archive"
  bzip2 -d -c ./source.tar.bz2 | tar -x --strip-components=1 -C "source"
  check_errors
 ;;
 "local")
  mkdir "source"
  check_errors
  bzip2 -d -c "${cfg[build.src.link]}" | tar -x --strip-components=1 -C "source"
  check_errors
 ;;
esac

cd "source"
check_errors

exec_cmd() {
 local phase="$1"
 local cmd="$2"
 echo "$phase: ${cfg[build.build_seq.$phase]}"
 eval "${cfg[build.build_seq.$phase]}"
}

#execure build commands
for phase in "prepare" "configure" "make" "install"
do
 cnt="1"
 while `check_lua_export "build.build_seq.$phase.$cnt"`
 do
  exec_cmd "$phase.$cnt"
  check_errors
  cnt=`expr $cnt + 1`
 done
done

#cleanup
echo "wine build config"
cd "$script_dir"
rm -rf "$tmp_dir"
exit 0

