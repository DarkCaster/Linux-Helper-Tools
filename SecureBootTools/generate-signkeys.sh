#!/bin/bash

script_dir="$( cd "$( dirname "$0" )" && pwd )"

set -e

mkdir -p "$script_dir/keys"
cd "$script_dir/keys"

echo "creating new key and certificate used for signing"
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout private.key -out public.crt -nodes -days 3650 -subj "/CN=PUBLIC/"

echo "converting certificate to der format"
openssl x509 -in public.crt -outform der -out public.der

echo "encrypting private key"
openssl aes-256-cbc -a -e -salt -md sha512 -in private.key -out private.key.enc

echo "removing unencrypted key"
rm private.key
