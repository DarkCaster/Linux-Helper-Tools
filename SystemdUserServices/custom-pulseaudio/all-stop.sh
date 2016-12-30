#!/bin/sh

script_dir="$( cd "$( dirname "$0" )" && pwd )"
"$script_dir"/pulse-stop.sh
code="$?"
test "z$code" != "z0" && exit $code
"$script_dir"/save-alsa-levels.sh
exit 0

