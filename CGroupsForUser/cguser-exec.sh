#!/bin/bash

show_usage() {
  echo "usage: cguser-exec.sh <options> <command> [parameters]"
  echo "options:"
  echo "  -n <cg name> - run command within already created cgroup"
  echo "     (for now only cpu and memory) inside base 'cgusers' cgroup"
  echo "     any other options are ignored when running in this mode"
  echo "  -t - run command inside newly created temporary cgroup"
  echo "     remove it upon command exit, limits may be applied with other options (todo)"
  echo "  -c <timeout seconds> - timeout when trying to remove temporary cgroup on exit"
  echo "  -m <memory limit in bytes, optionally K,M,G suffixes allowed> - memory limit for temporary cgroup"
  echo "  -msw <memsw limit in bytes, optionally K,M,G suffixes allowed> - memsw limit for temporary cgroup, must be > memory limit"
  echo "  -ms <soft memory limit in bytes, optionally K,M,G suffixes allowed> - soft memory limit for temporary cgroup, should be < memory limit"
  echo "  -iw <io weight> - io weight for blkio controller, will be applied to blkio.weight or blkio.bfq.weight depending on availability"
  exit 1
}

cgctl="memory,cpu"
createcg="false"
cgbase="cgusers"
cgtimeout="0"

is_number() {
  local num="$1"
  [ ! -z "${num##*[!0-9]*}" ] && return 0 || return 1
}

while true; do
  if [ "$1" = "-n" ]; then
    shift 1
    cgname="$cgbase/$1"
    [[ -z "$cgname" ]] && show_usage
  elif [ "$1" = "-t" ]; then
    cgname=$(tr </dev/urandom -cd '[:alnum:]' | head -c8)
    cgname="$cgbase/$cgname"
    createcg="true"
  elif [ "$1" = "-c" ]; then
    shift 1
    cgtimeout="$1"
    if ! is_number "$cgtimeout"; then
      echo "provided timeout value is not a number"
      show_usage
    fi
  elif [ "$1" = "-m" ]; then
    shift 1
    memlimit="$1"
  elif [ "$1" = "-ms" ]; then
    shift 1
    memsoftlimit="$1"
  elif [ "$1" = "-msw" ]; then
    shift 1
    memswlimit="$1"
  elif [ "$1" = "-iw" ]; then
    shift 1
    ioweight="$1"
  else
    command="$1"
    shift 1
    break
  fi
  shift 1
done

[[ -z "$cgname" ]] && echo "you must provide -n or -t option" && show_usage
[[ -z "$command" ]] && echo "command is missing" && show_usage

if [[ $createcg = true ]]; then
  cgcreate -g $cgctl:$cgname
  [[ ! -z "$memlimit" ]] && echo "$memlimit" >/sys/fs/cgroup/memory/$cgname/memory.limit_in_bytes
  [[ ! -z "$memswlimit" ]] && echo "$memswlimit" >/sys/fs/cgroup/memory/$cgname/memory.memsw.limit_in_bytes
  [[ ! -z "$memsoftlimit" ]] && echo "$memsoftlimit" >/sys/fs/cgroup/memory/$cgname/memory.soft_limit_in_bytes
  if [[ ! -z "$ioweight" ]]; then
    echo "$ioweight" >/sys/fs/cgroup/blkio/$cgname/blkio.bfq.weight
    echo "$ioweight" >/sys/fs/cgroup/blkio/$cgname/blkio.weight
  fi
fi

#run command
cgexec -g $cgctl:$cgname "$command" "$@"
ec="$?"

try_cgdelete() {
  local cg_ec="0"
  cgdelete -r -g $cgctl:$cgname
  cg_ec="$?"
  while [[ $cgtimeout -gt 0 && $cg_ec != 0 ]]; do
    sleep 1
    ((cgtimeout -= 1))
    cgdelete -r -g $cgctl:$cgname
    cg_ec="$?"
  done
}

if [[ $createcg = true ]]; then
  try_cgdelete
fi

exit "$ec"
