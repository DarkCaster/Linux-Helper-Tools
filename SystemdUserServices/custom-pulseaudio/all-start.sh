#!/bin/sh

script_dir="$( cd "$( dirname "$0" )" && pwd )"
"$script_dir"/restore-alsa-levels.sh
"$script_dir"/pulse-start.sh
code="$?"
exit $code

