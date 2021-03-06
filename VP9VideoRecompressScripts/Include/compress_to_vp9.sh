#!/bin/bash

video_src="$1"
video_dest="$2"
format="$3"
vprofile="$4"
aprofile="$5"
temp_dir="$6"
vpxenc="$7"
denoise="$8"
deinterlace="$9"

shift 1
crop="$9"

shift 1
bitdepth="$9"

shift 1
video_only="$9"

shift 1
use_tempfile="$9"

shift 1
nnedi_weights="$9"

thisuser=`id -u`

test "z$temp_dir" = "z" && temp_dir=`mktemp -d -t vp9-compressor-$thisuser-XXXXXX` || temp_dir=`mktemp -p "$temp_dir" -d -t vp9-compressor-$thisuser-XXXXXX`
test "z$temp_dir" = "z" && exit 1

audio_opts=""

video_base_opts=""
video_fp_opts=""
video_sp_opts=""
video_op_opts=""
denoise_opts=""
deinterlace_opts=""
crop_opts=""

#ffmpeg extra filter options
filter_extra=""

use_vpxenc="true"
use_tp="false"
use_mkvmerge="false"

#bitdepth options
ffbitopts=""
ffpixopts=""
vpxbitopts=""

# custom bitdepth and pix format
if [[ ! -z $bitdepth ]]; then
 ffbitopts="-strict -1"
 ffpixopts="-pix_fmt $bitdepth"
 #TODO: vpx profile selection, now binded to profile 0 for any custom pix format
 vpxbitopts="--profile=0"
fi

# force convert source to yuv420p 8-bit format before passing it to vpxenc
if [[ "$bitdepth" = "yuv420p" ]]; then
 ffbitopts=""
 ffpixopts="-pix_fmt yuv420p"
 vpxbitopts="--profile=0"
fi

# simple 10 bit profile, for use with non-hdr 8-bit source, pix_fmt will be autodetected
if [[ "$bitdepth" = "10" ]]; then
 ffbitopts="-strict -1"
 ffpixopts="-pix_fmt +"
 vpxbitopts="--profile=2 --bit-depth=10"
fi

# simple 12 bit profile, for use with non-hdr 8-bit source, pix_fmt will be autodetected
if [[ "$bitdepth" = "12" ]]; then
 ffbitopts="-strict -1"
 ffpixopts="-pix_fmt +"
 vpxbitopts="--profile=2 --bit-depth=12"
fi

# profile for HDR 10-bit source (use ffprobe to query): yuv420p10le(tv, bt2020nc/bt2020/smpte2084)
# pix_fmt passed to vpxenc will be set to yuv420p10le
if [[ "$bitdepth" = "yuv420p10le_tv_bt2020nc_bt2020_smpte2084" ]]; then
 ffbitopts="-strict -1"
 ffpixopts="-pix_fmt yuv420p10le"
 vpxbitopts="--profile=2 --bit-depth=10 --color-space=bt2020"
 # needed to set remaining color meta headers that was not set by vpxenc
 mkvmergeopts="--colour-transfer-characteristics 0:16 --colour-primaries 0:9" #https://mkvtoolnix.download/doc/mkvmerge.html
 use_mkvmerge="true" # mkvmerge -o test.mkv  video.webm
fi

#default bitdepth and pix format
if [ "z$bitdepth" = "z" ] || [ "z$bitdepth" = "znone" ]; then
 ffbitopts=""
 ffpixopts="-pix_fmt +"
 vpxbitopts="--profile=0"
fi

#audio profiles setup

if [ "z$aprofile" = "z0" ]; then
 audio_opts=""
fi


if [ "z$aprofile" = "z1" ]; then
 audio_opts="-c:a libopus -b:a 192k"
fi

if [ "z$aprofile" = "z2" ]; then
 audio_opts="-c:a libopus -b:a 160k"
fi

if [ "z$aprofile" = "z3" ]; then
 audio_opts="-c:a libopus -b:a 128k"
fi

if [ "z$aprofile" = "z4" ]; then
 audio_opts="-c:a libopus -b:a 96k"
fi


if [ "z$aprofile" = "zv1" ]; then
 audio_opts="-c:a libvorbis -q:a 6"
fi

if [ "z$aprofile" = "zv2" ]; then
 audio_opts="-c:a libvorbis -q:a 5"
fi

if [ "z$aprofile" = "zv3" ]; then
 audio_opts="-c:a libvorbis -q:a 4"
fi

if [ "z$aprofile" = "zv4" ]; then
 audio_opts="-c:a libvorbis -q:a 2"
fi

if [ "z$aprofile" = "zno" ]; then
 audio_opts="-an"
fi


#profile 0 - use ffmpeg to copy all streams, optionally recompress audio
if [[ "$vprofile" = "0" ]]; then
 use_vpxenc="false"
fi

if [[ "$vprofile" = "fast1" || "$vprofile" = "fast2" || "$vprofile" = "fast3" || "$vprofile" = "fast4" || "$vprofile" = "fast5" || "$vprofile" = "fast6" ]]; then
  use_tp="true"
  video_op_opts="--good --cpu-used=2"
  video_fp_opts="--good --cpu-used=2 --auto-alt-ref=1 --lag-in-frames=25 --arnr-maxframes=15 --arnr-strength=3 --minsection-pct=5 --maxsection-pct=800 --bias-pct=50"
  video_sp_opts="--good --cpu-used=2 --auto-alt-ref=1 --lag-in-frames=25 --arnr-maxframes=15 --arnr-strength=3 --minsection-pct=5 --maxsection-pct=800 --bias-pct=50"

  [[ "$vprofile" = "fast1" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=10000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "fast2" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=7500 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "fast3" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=5000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "fast4" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=3000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "fast5" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=2000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "fast6" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=1000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
fi

if [[ "$vprofile" = "cq1" || "$vprofile" = "cq2" || "$vprofile" = "cq3" || "$vprofile" = "cq4" || "$vprofile" = "cq5" || "$vprofile" = "cq6" || "$vprofile" = "1" || "$vprofile" = "2" || "$vprofile" = "3" || "$vprofile" = "4" || "$vprofile" = "5" || "$vprofile" = "6" ]]; then
  use_tp="true"
  video_op_opts="--good --cpu-used=1"
  video_fp_opts="--good --cpu-used=1 --auto-alt-ref=1 --lag-in-frames=25 --arnr-maxframes=15 --arnr-strength=3 --minsection-pct=5 --maxsection-pct=800 --bias-pct=50"
  video_sp_opts="--good --cpu-used=1 --auto-alt-ref=1 --lag-in-frames=25 --arnr-maxframes=15 --arnr-strength=3 --minsection-pct=5 --maxsection-pct=800 --bias-pct=50"

  [[ "$vprofile" = "cq1" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=1 --target-bitrate=10000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "cq2" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=8 --target-bitrate=7500 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "cq3" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=16 --target-bitrate=5000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "cq4" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=22 --target-bitrate=3000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "cq5" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=33 --target-bitrate=2000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "cq6" ]] && video_base_opts="--codec=vp9 --end-usage=cq --cq-level=44 --target-bitrate=1000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"

  [[ "$vprofile" = "1" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=10000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "2" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=7500 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "3" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=5000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "4" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=3000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "5" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=2000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
  [[ "$vprofile" = "6" ]] && video_base_opts="--codec=vp9 --end-usage=vbr --target-bitrate=1000 --buf-initial-sz=10000 --buf-optimal-sz=12000 --buf-sz=16000 --threads=1 --aq-mode=1 --tile-rows=0 --tile-columns=0 --frame-parallel=0 --static-thresh=0 --drop-frame=0 --resize-allowed=0 --kf-min-dist=0 --kf-max-dist=1440"
fi

usefilters="no"
filters=""

#denoise filter setup
test "z$denoise" != "z"  && denoise_opts="$denoise"

test "z$denoise" = "z0"  && denoise_opts=""
test "z$denoise" = "z1"  && denoise_opts="hqdn3d=0.5"
test "z$denoise" = "z2"  && denoise_opts="hqdn3d=1"
test "z$denoise" = "z3"  && denoise_opts="hqdn3d=1.5"
test "z$denoise" = "z4"  && denoise_opts="hqdn3d=2"
test "z$denoise" = "z5"  && denoise_opts="hqdn3d=2.5"
test "z$denoise" = "z6"  && denoise_opts="hqdn3d=3"
test "z$denoise" = "z7"  && denoise_opts="hqdn3d=3.5"
test "z$denoise" = "z8"  && denoise_opts="hqdn3d=4"
test "z$denoise" = "z9"  && denoise_opts="hqdn3d=4.5"
test "z$denoise" = "z10" && denoise_opts="hqdn3d=5"
test "z$denoise" = "z11" && denoise_opts="hqdn3d=5.5"
test "z$denoise" = "z12" && denoise_opts="hqdn3d=6"
test "z$denoise" = "z13" && denoise_opts="hqdn3d=6.5"
test "z$denoise" = "z14" && denoise_opts="hqdn3d=7"
test "z$denoise" = "z15" && denoise_opts="hqdn3d=7.5"
test "z$denoise" = "z16" && denoise_opts="hqdn3d=8"
test "z$denoise" = "z17" && denoise_opts="hqdn3d=8.5"
test "z$denoise" = "z18" && denoise_opts="hqdn3d=9"
test "z$denoise" = "z19" && denoise_opts="hqdn3d=9.5"
test "z$denoise" = "z20" && denoise_opts="hqdn3d=10"

#special denose preset levels

#all parameters +0.5 levels (params between $denoise=1 and $denoise=2
test "z$denoise" = "z1+0.5"  && denoise_opts="hqdn3d=0.75"

#all parameters +0.5 levels (params between $denoise=2 and $denoise=3
test "z$denoise" = "z2+0.5"  && denoise_opts="hqdn3d=1.25"

#luma strength +2 levels (equalent to $denoise=4), chroma strength +2 levels (equalent to value at $denoise=4), luma tmp +0.05 levels (sligtly more than value at $denoise=2)
#good for higher contrast noise on dark areas, but do not add any strong temporal artefacts (luma and chroma tails) that can be visible on recompressed material
test "z$denoise" = "z2_ls+2_cs+2_lt+0.05"  && denoise_opts="hqdn3d=2:1.5:1.6:1.125"

test "z$denoise" = "z"   && denoise_opts=""
test "z$vprofile" = "z0" && denoise_opts=""

test ! -z "$denoise_opts" && usefilters="yes"

#deinterlace filter setup
test "z$deinterlace" != "z"  && deinterlace_opts="$deinterlace"
test "z$deinterlace" = "z0"  && deinterlace_opts=""
test "z$deinterlace" = "zbfr"  && deinterlace_opts="bwdif=0:-1:0"
test "z$deinterlace" = "zbfi"  && deinterlace_opts="bwdif=1:-1:0"
test "z$deinterlace" = "zk1"  && deinterlace_opts="kerndeint=0"
test "z$deinterlace" = "zk2"  && deinterlace_opts="kerndeint=10"
test "z$deinterlace" = "zk3"  && deinterlace_opts="kerndeint=128"
test "z$deinterlace" = "zk1s"  && deinterlace_opts="kerndeint=thresh=0:sharp=1"
test "z$deinterlace" = "zk2s"  && deinterlace_opts="kerndeint=thresh=10:sharp=1"
test "z$deinterlace" = "zk3s"  && deinterlace_opts="kerndeint=thresh=128:sharp=1"
test "z$deinterlace" = "znhq"  && deinterlace_opts="nnedi=nns=n256:qual=slow:pscrn=new"
test "z$deinterlace" = "znlq"  && deinterlace_opts="nnedi=nns=n32:qual=fast:pscrn=new"
test "z$deinterlace" = "zw"  && deinterlace_opts="w3fdif"
test "z$deinterlace" = "zyfr"  && deinterlace_opts="yadif=0:-1:0"
test "z$deinterlace" = "zyfi"  && deinterlace_opts="yadif=1:-1:0"

test "z$deinterlace" = "z"   && deinterlace_opts=""
test "z$vprofile" = "z0"     && deinterlace_opts=""

test ! -z "$deinterlace_opts" && usefilters="yes"

#crop filter setup
test "z$crop" != "z"      && crop_opts="$crop"
test "z$crop" = "z0"      && crop_opts=""
test "z$crop" = "zfhd4x3" && crop_opts="crop=1440:1080:240:0"
test "z$crop" = "zfhd4x3ext" && crop_opts="crop=1520:1080:200:0"
test "z$crop" = "zresize_fhd" && crop_opts="scale=1920:-1" && filter_extra="-sws_flags spline"
test "z$crop" = "z"       && crop_opts=""

test "z$vprofile" = "z0"  && crop_opts="" && filter_extra=""

test ! -z "$crop_opts" && usefilters="yes"

if [ "$usefilters" = "yes" ]; then
 filters="-vf "
 cnt=0
 fstr="$crop_opts $deinterlace_opts $denoise_opts"
 for i in $fstr; do let cnt=cnt+1; done
 for i in $fstr;
 do
  filters="${filters}${i}"
  let cnt=cnt-1
  test $cnt -gt 0 && filters="$filters,"
 done
fi

check_errors () {
 local status="$?"
 if [ "$status" != "0" ]; then
  echo "ERROR: compress_to_vp9.sh script failed. see it's stuff at $temp_dir"
  exit 1
 fi
}

olddir="$PWD"
cd "$temp_dir"
check_errors

if [ ! -z "$nnedi_weights" ]; then
 cp "$nnedi_weights" .
 check_errors
fi

echo "selected compression parameters:" >> "$temp_dir/ffmpeg.log"
echo "use_vpxenc=$use_vpxenc" >> "$temp_dir/ffmpeg.log"
test "z$use_vpxenc" = "ztrue" && echo "vpxenc=$vpxenc" >> "$temp_dir/ffmpeg.log"
echo "use_tp=$use_tp" >> "$temp_dir/ffmpeg.log"
echo "video_base_opts=$video_base_opts" >> "$temp_dir/ffmpeg.log"
echo "video_fp_opts=$video_fp_opts" >> "$temp_dir/ffmpeg.log"
echo "video_sp_opts=$video_sp_opts" >> "$temp_dir/ffmpeg.log"
echo "video_op_opts=$video_op_opts" >> "$temp_dir/ffmpeg.log"
echo "filters=$filters" >> "$temp_dir/ffmpeg.log"
echo "filter_extra=$filter_extra" >> "$temp_dir/ffmpeg.log"
echo "audio_opts=$audio_opts" >> "$temp_dir/ffmpeg.log"
echo "ffbitopts=$ffbitopts" >> "$temp_dir/ffmpeg.log"
echo "ffpixopts=$ffpixopts" >> "$temp_dir/ffmpeg.log"
echo "vpxbitopts=$vpxbitopts" >> "$temp_dir/ffmpeg.log"

echo -n "source file md5=" >> "$temp_dir/ffmpeg.log"
cat "$video_src" | md5sum -b | cut -f1 -d' ' >> "$temp_dir/ffmpeg.log"

video_src_bak=""

if [ "z$use_tempfile" = "zyes" ]; then
 #create preprocessed video file
 echo "****ffmpeg preprocess output****" >> "$temp_dir/ffmpeg.log"
 </dev/null 2>>"$temp_dir/ffmpeg.log" ffmpeg -loglevel info -i "$video_src" -threads 1 -map 0:v -map_chapters -1 $filters $filter_extra -c:v ljpeg -f matroska -strict -1 "$temp_dir/temp_source.mkv"
 check_errors
 #clean filters string, because we applying filters on preprocessing
 filters=""
 filter_extra=""
 #redirect video source to preprocessed temporary file
 video_src_bak="$video_src"
 video_src="$temp_dir/temp_source.mkv"
fi

if [[ "$use_vpxenc" != "true" ]]; then
  #process without vpxenc, just copy video stream
  echo "*********ffmpeg output*********" >> "$temp_dir/ffmpeg.log"
  </dev/null ffmpeg -i "$video_src" -map 0 -c copy --threads 1 $audio_opts -f $format "$temp_dir/video.result" >> "$temp_dir/ffmpeg.log" 2>&1
  check_errors
else
 if [[ "$use_tp" = "true" ]]; then

  #process with vpxenc, two pass encode, first pass
  echo "****ffmpeg 1-st pass output****" >> "$temp_dir/ffmpeg.log"
  echo "****vpxenc 1-st pass output****" >> "$temp_dir/vpxenc.log"
  </dev/null 2>>"$temp_dir/ffmpeg.log" ffmpeg -loglevel info -i "$video_src" -threads 1 -map 0:v -map_chapters -1 $filters $filter_extra -c:v wrapped_avframe $ffpixopts -f yuv4mpegpipe $ffbitopts - | 2>>"$temp_dir/vpxenc.log" "$vpxenc" $vpxbitopts --passes=2 --pass=1 --fpf=passlog.log $video_base_opts $video_fp_opts -o "$temp_dir/video-firstpass.webm" -
  codes=`echo ${PIPESTATUS[@]}`
  test "$codes" != "0 0" && echo "ffmpeg or vpxenc failed at first pass with exit codes=$codes. see it's stuff at $temp_dir" && exit 1

  #second pass
  echo "****ffmpeg 2-nd pass output****" >> "$temp_dir/ffmpeg.log"
  echo "****vpxenc 2-nd pass output****" >> "$temp_dir/vpxenc.log"
  </dev/null 2>>"$temp_dir/ffmpeg.log" ffmpeg -loglevel info -i "$video_src" -threads 1 -map 0:v -map_chapters -1 $filters $filter_extra -c:v wrapped_avframe $ffpixopts -f yuv4mpegpipe $ffbitopts - | 2>>"$temp_dir/vpxenc.log" "$vpxenc" $vpxbitopts --passes=2 --pass=2 --fpf=passlog.log $video_base_opts $video_sp_opts -o "$temp_dir/video.webm" -
  codes=`echo ${PIPESTATUS[@]}`
  test "$codes" != "0 0" && echo "ffmpeg or vpxenc failed at second pass with exit codes=$codes. see it's stuff at $temp_dir" && exit 1

 else

  #process with vpxenc, one pass encode
  echo "*********ffmpeg output*********" >> "$temp_dir/ffmpeg.log"
  echo "*********vpxenc output*********" >> "$temp_dir/vpxenc.log"
  </dev/null 2>>"$temp_dir/ffmpeg.log" ffmpeg -loglevel info -i "$video_src" -threads 1 -map 0:v -map_chapters -1 $filters $filter_extra -c:v wrapped_avframe $ffpixopts -f yuv4mpegpipe $ffbitopts - | 2>>"$temp_dir/vpxenc.log" "$vpxenc" $vpxbitopts --passes=1 $video_base_opts $video_op_opts -o "$temp_dir/video.webm" -
  codes=`echo ${PIPESTATUS[@]}`
  test "$codes" != "0 0" && echo "ffmpeg or vpxenc failed with exit codes=$codes. see it's stuff at $temp_dir" && exit 1

 fi

 if [[ "$use_mkvmerge" = "true" ]]; then
  echo "*********mkvmerge extra pass output*********" >> "$temp_dir/ffmpeg.log"
  </dev/null mkvmerge -w -o "$temp_dir/video2.webm" $mkvmergeopts "$temp_dir/video.webm" >> "$temp_dir/ffmpeg.log" 2>&1
  check_errors
  mv "$temp_dir/video2.webm" "$temp_dir/video.webm"
  check_errors
 fi

 if [ "z$video_only" = "zyes" ]; then
  echo "****ffmpeg mux pass output (video_only)*****" >> "$temp_dir/ffmpeg.log"
  </dev/null ffmpeg -i "$temp_dir/video.webm" -threads 1 -c copy -f $format "$temp_dir/video.result" >> "$temp_dir/ffmpeg.log" 2>&1
  check_errors
 else
  #restore original video_src if using temporary preprocess file
  test ! -z "$video_src_bak" && video_src="$video_src_bak"
  #mux compressed videostream from video.webm and mux and recompress all other streams from source
  echo "****ffmpeg mux pass output*****" >> "$temp_dir/ffmpeg.log"
  </dev/null ffmpeg -i "$video_src" -i "$temp_dir/video.webm" -threads 1 -map 1:v -map 0 -map -0:v -c copy $audio_opts -f $format "$temp_dir/video.result" >> "$temp_dir/ffmpeg.log" 2>&1
  check_errors
 fi

fi

cd "$olddir"
check_errors

mv "$temp_dir/video.result" "$video_dest"
check_errors

if [ "z$use_vpxenc" == "ztrue" ]; then
  cat "$temp_dir/ffmpeg.log" "$temp_dir/vpxenc.log" > "$video_dest.log"
  check_errors
else
  mv "$temp_dir/ffmpeg.log" "$video_dest.log"
  check_errors
fi

#compress log
xz -9e "$video_dest.log"
check_errors

#remove temporary dir
rm -rf "$temp_dir"
check_errors
