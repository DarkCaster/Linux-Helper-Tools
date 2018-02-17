#!/bin/bash

input="$1"
output="$2"

#because pesign do not support non interactive operation with encrypted NSS db-storage,
#shred util is mandatory to securely destroy unencrypted keys and NSS db that may be left on disk after script is complete.
shred_bin=`which shred 2>/dev/null`
[[ -z "$shred_bin" ]] && echo "shred utility is missing, cannot continue" && exit 1

#script_dir=`dirname "$0"`
script_dir="$( cd "$( dirname "$0" )" && pwd )"

show_usage () {
 echo "usage: sign-efi-binary.sh <input file> <output file>"
 exit 100
}

[[ -z "$input" ]] && show_usage
[[ -z "$output" ]] && show_usage
[[ ! -d "$script_dir/keys" ]] && echo "keys subdirectory is missing, run generate-signkeys.sh first" && exit 1

dbdir=`mktemp -d`
echo "using temp dir: $dbdir"

set -eE

cleanup () {
 if [[ ! -z "$dbdir" && -d "$dbdir" ]]; then
  echo "cleaning up temp dir $dbdir"
  "$shred_bin" "$dbdir"/* || true
  rm -rf "$dbdir"
 fi
}

trap 'cleanup' ERR EXIT

test -z "$dbdir" && echo "error creting temp directory" && exit 1
test ! -d "$dbdir" && echo "error creting temp directory" && exit 1

#decrypt private key
echo "decrypting private key, and converting it to PKCS#12"
openssl aes-256-cbc -d -a -in "$script_dir/keys/private.key.enc" | cat - "$script_dir/keys/public.crt" | openssl pkcs12 -export -passout pass: -name signcert -out "$dbdir/signcert.p12"

echo "generating NSS database"
certutil -N --empty-password -d "$dbdir" -f /dev/stdin

echo "importing PKCS#12 sign cert"
pk12util -i "$dbdir/signcert.p12" -d "$dbdir" -W ""

echo "signing $input and saving it as $output"
pesign -s -n "$dbdir" -c signcert -i "$input" -o "$output"
