#!/bin/bash

video_src="$1"
video_dest="$2"

temp_dir_base="$3"
name_pattern="$4"
vprofile="$5"
aprofile="$6"
denoise="$7"
deinterlace="$8"
crop="$9"

shift 1
bitdepth="$9"

shift 1
jobs_count="$9"

shift 1
video_only="$9"

show_usage () {
 echo "usage: <video_src dir> <video_dest dir> [temp_dir_base] [name_pattern] [vprofile] [aprofile] [video denoise profile number 0-20, or custom video filter] [deinterlace profile name, or custom video filter] [crop profile name, or custom video filter] [codec bitdepth or force pixfmt 8-10-12-yuv420p-<custom pixfmt string>] [jobs_count] [video_only yes-no]"
 exit 1
}

test "z$video_src" = "z" && show_usage
test "z$video_dest" = "z" && show_usage

test "z$vprofile" = "z" && vprofile="0"
test "z$aprofile" = "z" && aprofile="0"

test "z$video_only" = "z" && video_only="no"

format="matroska"
ext="mkv"
temp_dir="/tmp"

cpu_num="1"
test "z$jobs_count" = "z" && cpu_num="`nproc 2> /dev/null`" || cpu_num="$jobs_count"

test "z$bitdepth" = "z" && bitdepth="none"

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  echo "ERROR: main recompressor script failed!"
  exit 1
 fi
}

do_exit () {
 local code="$1"
 rm -rf "$temp_dir"
 exit $code
}

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

#find vpxenc
vpxenc=`which "$script_dir/Utils/Deps/bin/vpxenc" 2>/dev/null`
test "z$vpxenc" = "z" && vpxenc=`which vpxenc 2>/dev/null`

echo "launch parameters:"
echo "******************"
echo "vpxenc utility=$vpxenc"
echo "video_src=$video_src"
echo "video_dest=$video_dest"
echo "temp_dir_base=$temp_dir_base"
echo "name_pattern=$name_pattern"
echo "vprofile=$vprofile"
echo "aprofile=$aprofile"
echo "denoise=$denoise"
echo "deinterlace=$deinterlace"
echo "crop=$crop"
echo "bitdepth=$bitdepth"
echo "jobs count=$cpu_num"
echo "video_only=$video_only"
echo "******************"

if [ ! -d "$temp_dir_base" ]; then
 echo "creating tempdir"
 mkdir -p "$temp_dir_base"
 check_errors
fi

thisuser=`id -u`
test "z$temp_dir_base" = "z" && temp_dir=`mktemp -d -t video-recompressor-base-script-$thisuser-XXXXXX` || temp_dir=`mktemp -p "$temp_dir_base" -d -t video-recompressor-base-script-$thisuser-XXXXXX`
test "z$temp_dir" = "z" && false || true
check_errors

confirm="n"

if [ "zzz$name_pattern" = "zzz" ]; then
	confirm="n"
	echo "Enter filename pattern (just press enter for default *.avi pattern)"
	read name_pattern
	if [ "zzz$name_pattern" = "zzz" ]; then
		name_pattern="*.avi"
	fi
fi

echo "Rebuilding videos from $video_src with name pattern $name_pattern"

if [ ! -d "$video_dest" ]; then
	echo "Creating destination directory"
	mkdir "$video_dest"
	check_errors
fi

echo "Fetching filelist"
find "$video_src" -maxdepth 1 -name "$name_pattern" -type f | sort > "$temp_dir/filelist.txt"
check_errors

echo "Files to be processed:"
echo "**********************"
while read line
do
	filename=`basename "$line"`
	echo "$filename"
done < "$temp_dir/filelist.txt"
echo "**********************"

if [ "$confirm" = "n" ]; then
 echo "confirm? (y\n)"
 read confirm
 if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  do_exit 0
 fi
fi

for i in $(seq "$cpu_num"); do
 touch "$temp_dir/filelist_chunk_$i.txt"
done

chunk=1

while read line
do
 echo "$line" >> "$temp_dir/filelist_chunk_$chunk.txt"
 chunk=`expr $chunk + 1`
 test $chunk -gt $cpu_num && chunk=1 
done < "$temp_dir/filelist.txt"

for i in $(seq "$cpu_num"); do
 "$script_dir/Include/recompress-chunk.sh" "$i" "$temp_dir/filelist_chunk_$i.txt" "$video_dest" "$script_dir/Include/compress_to_vp9.sh" $format $ext $vprofile $aprofile "$temp_dir_base" "$vpxenc" "$denoise" "$deinterlace" "$crop" "$bitdepth" "$video_only" &
 pids="$pids $!"
 sleep 1
done

wait $pids

echo "Video rebuild complete!"
do_exit 0

