#!/bin/bash

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

log () {
 local msg="$@"
 echo "$msg"
}

check_errors () {
 local status="$?"
 local msg="$@"
 if [ "$status" != "0" ]; then
  if [ "z$msg" != "z" ]; then
   log "$msg"
  else
   log "ERROR: last operation finished with error code $status"
  fi
  exit $status
 fi
}

olddir=`pwd`

mkdir -p "$script_dir/keys"
check_errors

cd "$script_dir/keys"
check_errors

log "creating new key and certificate used for signing"
openssl req -new -x509 -newkey rsa:2048 -sha256 -keyout private.key -out public.crt -nodes -days 3650 -subj "/CN=PUBLIC/"
check_errors

log "converting certificate to der format"
openssl x509 -in public.crt -outform der -out public.der
check_errors

log "encrypting private key"
openssl aes-256-cbc -a -salt -in private.key -out private.key.enc
check_errors

log "removing unencrypted key"
rm private.key
check_errors

cd "$olddir"
check_errors
