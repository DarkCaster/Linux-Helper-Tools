#!/bin/bash

set -e

script_dir="$( cd "$( dirname "$0" )" && pwd )"
cd "$script_dir"

# for generating on loder PEM format
# ssh-keygen -t rsa -b 4096 -m PEM

ssh-keygen -b 521 -t ecdsa -f ansible.key
