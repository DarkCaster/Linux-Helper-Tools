#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
cd "$script_dir"

ssh-keygen -b 521 -t ecdsa -f ssh_key
