#!/bin/sh
#

rm __HOME/.config/autostart/dropbox.desktop >/dev/null 2>&1
__DROPBOX start
rm __HOME/.config/autostart/dropbox.desktop >/dev/null 2>&1

exit 0

