#!/bin/bash

show_usage() {
  echo "usage: cguser-exec.sh [options] <command> [parameters]"
  echo "options:"
  echo "  -n <cg name> - run command within already created cgroup"
  echo "     (for now only cpu and memory) inside base 'cgusers' cgroup"
  echo "     any other options are ignored when running in this mode"
  echo "  -t - run command inside newly created temporary cgroup"
  echo "     remove it upon command exit, limits may be applied with other options (todo)"
  exit 1
}

cgctl="memory,cpu"
createcg="false"
cgbase="cgusers"

while true; do
  if [ "$1" = "-n" ]; then
    shift 1
    cgname="$cgbase/$1"
    [[ -z "$cgname" ]] && show_usage
  elif [ "$1" = "-t" ]; then
    cgname=$(tr </dev/urandom -cd '[:alnum:]' | head -c8)
    cgname="$cgbase/$cgname"
    createcg="true"
  else
    command="$1"
    shift 1
    break
  fi
  shift 1
done

[[ -z "$command" ]] && echo "command is missing" && show_usage

if [[ $createcg = true ]]; then
  cgcreate -g $cgctl:$cgname
fi

#run command
cgexec -g $cgctl:$cgname "$command" "$@"
ec="$?"

if [[ $createcg = true ]]; then
  cgdelete -r -g $cgctl:$cgname
fi

exit "$ec"
