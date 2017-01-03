#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

"$script_dir"/netjack-start.sh
code="$?"

test "z$code" != "z0" && exit $code

"$script_dir"/alsaout-start.sh
code="$?"

if [ "z$code" != "z0" ]; then
 "$script_dir"/alsaout-stop.sh
 "$script_dir"/netjack-stop.sh
 exit $code
fi

exit 0

