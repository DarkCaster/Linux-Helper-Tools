# Squashfs Mounter

Destop file, mime package, and helper scripts to perform mounting squashfs images from userspace.
Using udiskctl to perform mount operations.
This should work, if user have required removable device mount permissions from policykit.
Losetup utility also needed (no superuser right required, used to detect loop device status).

This script is experimental, and may not work as intended. For now, it tested only with MATE DE.
USE AT YOUR OWN RISK!

