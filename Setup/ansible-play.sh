#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
cd "$script_dir"

target="$1"
[[ -z $target ]] && echo "usage: ansible-play.sh <yml playbook>" && exit 1
[[ ! -f $target ]] && echo "target playbook file is missing" && exit 1

target_file=`realpath -e "$target"`
target_dir=`dirname "$target_file"`
cd "$target_dir"

ansible-playbook --private-key="$script_dir/00_ansible_key/ansible.key" -i "$script_dir/ansible-inventory" "$target_file"
