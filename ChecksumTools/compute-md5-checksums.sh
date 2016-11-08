#!/bin/sh

show_usage () {
 echo "usage: compute-md5-checksums.sh <dest-path> <checksums-list-file>"
 exit 1
}

dest="$1"
test -z "$dest" && show_usage
test ! -e "$dest" && echo "$dest path not exist" && exit 1

output="$2"
test -z "$output" && show_usage
output=`realpath "$output"`
test -f "$output" && echo "checksums file list $output already exist" && exit 1

olddir="$PWD"
cd "$dest"

find . -mount -type f -printf '%P\n' | sort | while read line
do
  echo "processing file: $line"
  md5sum -b "$line" >> "$output"
  test "$?" != "0" && echo "error while processing $line" && exit 1
done

cd "$olddir"

