#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

"$script_dir"/alsaout-stop.sh
"$script_dir"/netjack-stop.sh

exit 0

