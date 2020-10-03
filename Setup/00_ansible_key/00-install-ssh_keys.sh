#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
cd "$script_dir"

ansible-playbook --ask-pass -i ansible-inventory 00-install-ssh-keys.yml
