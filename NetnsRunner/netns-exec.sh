#!/bin/dash

[ -z "$SUDO_UID" ] && echo "SUDO_UID env variable is not defined or empty!" && exit 1
[ -z "$SUDO_GID" ] && echo "SUDO_GID env variable is not defined or empty!" && exit 1
[ "$SUDO_UID" = "0" ] && echo "SUDO_UID is 0, cannot proceed!" && exit 1
[ "$SUDO_GID" = "0" ] && echo "SUDO_GID is 0, cannot proceed!" && exit 1

user="$SUDO_USER"
group=`getent group "$SUDO_GID" | head -n1 | cut -f1 -d":"`

[ -z "$user" ] && echo "failed to detect invoking user!" && exit 1
[ -z "$group" ] && echo "failed to detect invoking user's group!" && exit 1
[ -z "$1" ] && echo "bg/fg parameter is empty" && exit 1
[ "$1" = "bg" ] && mode="-b" || mode=""
shift 1

[ -z "$1" ] && echo "namespace parameter is empty" && exit 1
namespace=`echo "$1" | grep "^[0-9a-z_]*$"`
[ -z "$namespace" ] && echo "namespace parameter is incorrect" && exit 1
[ ! -f "/var/run/netns/$namespace" ] && echo "selected network namespace $namespace is not available" && exit 1

shift 1
ip netns exec "$namespace" sudo $mode -u "$user" -g "$group" -- "$@"
