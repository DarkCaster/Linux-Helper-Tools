#!/bin/sh

script_dir="$( cd "$( dirname "$0" )" && pwd )"

systemctl --user import-environment ALSA_CONFIG_PATH AUDIODRIVER CONFIG_SITE CPU DBUS_SESSION_BUS_ADDRESS G_BROKEN_FILENAMES G_FILENAME_ENCODING HOST HOSTNAME HOSTTYPE LANG MACHTYPE OSTYPE QEMU_AUDIO_DRV SDL_AUDIODRIVER VDPAU_DRIVER DISPLAY XAUTHORITY XAUTHLOCALHOSTNAME XDG_CONFIG_DIRS XDG_DATA_DIRS

systemctl --user start desktop.target

