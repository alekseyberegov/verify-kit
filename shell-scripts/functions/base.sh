#/bin/bash

parse_url() {
    local prefix=$2

    proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"

    # remove the protocol
    url=$(echo $1 | sed -e s,$proto,,g)

    # extract the user (if any)
    user="$(echo $url | grep @ | cut -d@ -f1)"

    # extract the host and port 
    hostport=$(echo $url | sed -e s,$user@,,g | cut -d/ -f1)

    # by request host without port
    host="$(echo $hostport | sed -e 's,:.*,,g')"

    # by request - try to extract the port
    port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

    # extract the path (if any)
    path="$(echo $url | grep / | cut -d/ -f2-)"

    printf -- "%s%s=%s\n" "$prefix" "proto" $proto
    printf -- "%s%s=%s\n" "$prefix" "user" $user
    printf -- "%s%s=%s\n" "$prefix" "hostport" $hostport
    printf -- "%s%s=%s\n" "$prefix" "host" $host
    printf -- "%s%s=%s\n" "$prefix" "port" $port
    printf -- "%s%s=%s\n" "$prefix" "path" $path
}

url_encode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
  REPLY="${encoded}"
}

function join_by() { 
    local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; 
}

function abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}
