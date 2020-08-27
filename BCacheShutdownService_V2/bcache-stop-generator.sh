#!/bin/bash
#

# This systemd-generator script creates dynamic unit with the following logic:
# It will start before all devices from /etc/crypttab and stop after it.
# On stop it will try to cleanly deactivate all bcache cache devices listed at /sys/fs/bcache/*/ subdirectory
# and wait for all backing-store bcache devices deinitialized properly

output_dir="$3"

deps=()
deps_cnt=0

add_dep() {
  deps[$deps_cnt]="$1"
  (( deps_cnt += 1 ))
}

while read -r devname line_end
do
  add_dep "systemd-cryptsetup@${devname}.service"
done < "/etc/crypttab"

service_name="bcache-deactivate.service"
output_file="$output_dir/$service_name"

echo "[Unit]" > "$output_file"
echo "Description=Ensure clean shutdown of bcache devices" >> "$output_file"
echo "Before=shutdown.target ${deps[*]}" >> "$output_file"
echo "After=lvm2-monitor.service blk-availability.service" >> "$output_file"
echo "DefaultDependencies=no" >> "$output_file"
echo "Conflicts=shutdown.target" >> "$output_file"

echo "[Service]" >> "$output_file"
echo "ExecStart=/bin/true" >> "$output_file"
echo "ExecStop=__bcache_stop_script__" >> "$output_file"
echo "Type=oneshot" >> "$output_file"
echo "RemainAfterExit=true" >> "$output_file"
echo "TimeoutStopSec=240" >> "$output_file"

echo "[Install]" >> "$output_file"
echo "WantedBy=sysinit.target" >> "$output_file"

mkdir -p "$output_dir/sysinit.target.wants"
ln -s "$output_file" "$output_dir/sysinit.target.wants/$service_name"
