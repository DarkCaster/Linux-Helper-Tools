#!/bin/bash

input="$1"
output="$2"

#because pesign do not support non interactive operation with encrypted NSS db-storage,
#shred util is mandatory to securely destroy unencrypted keys and NSS db that may be left on disk after script is complete.
shred_bin=`which shred 2>/dev/null`
test -z "$shred_bin" && echo "shred utility is missing, cannot continue" && exit 1

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: sign-efi-binary.sh <input file> <output file>"
 exit 100
}

test -z "$input" && show_usage
test -z "$output" && show_usage
test ! -d "$script_dir/keys" && echo "keys subdirectory is missing, run generate-signkeys.sh first" && exit 1

log () {
 local msg="$@"
 echo "$msg"
}

dbdir=`mktemp -d`
log "using temp dir: $dbdir"

cleanup () {
 if [ ! -z "$dbdir" ] && [ -d "$dbdir" ]; then
  log "cleaning up"
  "$shred_bin" "$dbdir"/*
  rm -rf "$dbdir"
 fi
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
  cleanup
  exit $status
 fi
}

test -z "$dbdir" && log "error creting temp directory" && exit 1
test ! -d "$dbdir" && log "error creting temp directory" && exit 1

#decrypt private key
log "decrypting private key, and converting it to PKCS#12"
openssl aes-256-cbc -d -a -in "$script_dir/keys/private.key.enc" | cat - "$script_dir/keys/public.crt" | openssl pkcs12 -export -passout pass: -name signcert -out "$dbdir/signcert.p12"
check_errors

log "generating NSS database"
certutil -N --empty-password -d "$dbdir" -f /dev/stdin
check_errors

log "importing PKCS#12 sign cert"
pk12util -i "$dbdir/signcert.p12" -d "$dbdir" -W ""
check_errors

log "signing $input and saving it as $output"
pesign -s -n "$dbdir" -c signcert -i "$input" -o "$output"
check_errors

#cleanup
cleanup

exit 0

