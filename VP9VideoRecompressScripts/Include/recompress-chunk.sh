#!/bin/bash

jobid="$1"
filelist="$2"
dest="$3"
compressor="$4"
format="$5"
ext="$6"
vprofile="$7"
aprofile="$8"
temp_dir="$9"

shift 1
vpxenc="$9"

shift 1
denoise="$9"

shift 1
deinterlace="$9"

shift 1
crop="$9"

shift 1
bitdepth="$9"

shift 1
video_only="$9"

shift 1
nnedi_weights="$9"

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  exit $status
 fi
}

nice=`which nice 2>/dev/null`

while read line
do
 filename=`basename "$line"`
 fbname="${filename%.*}"
 echo "job #$jobid processing: $filename"
 $nice -n 19 $compressor "$line" "$dest/$fbname.$ext" $format $vprofile $aprofile "$temp_dir" "$vpxenc" "$denoise" "$deinterlace" "$crop" "$bitdepth" "$video_only" "$nnedi_weights"
 check_errors
done < "$filelist"

test `cat "$filelist" | wc -l` -gt 0 && echo "job #$jobid complete!"
exit 0

