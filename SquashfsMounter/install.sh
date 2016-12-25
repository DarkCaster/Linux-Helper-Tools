#!/bin/bash
#

script_dir="$( cd "$( dirname "$0" )" && pwd )"

#install mime type
mkdir -p ~/.local/share/mime/packages
cp "$script_dir/application-x-squashfs.xml" ~/.local/share/mime/packages/application-x-squashfs.xml
update-mime-database ~/.local/share/mime

#install mounter scripts
cp "$script_dir/mount-squashfs-image.sh" ~/bin/mount-squashfs-image.sh
chmod 755 ~/bin/mount-squashfs-image.sh

cp "$script_dir/umount-squashfs-image.sh" ~/bin/umount-squashfs-image.sh
chmod 755 ~/bin/umount-squashfs-image.sh

#install desktop file
cp "$script_dir/squashfs-mounter.desktop" ~/.local/share/applications/squashfs-mounter.desktop
update-desktop-database ~/.local/share/applications

