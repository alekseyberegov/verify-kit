#/bin/bash

parse_url() {
    local prefix=$2

    proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
    url=$(echo $1 | sed -e s,$proto,,g)
    user="$(echo $url | grep @ | cut -d@ -f1)"
    hostport=$(echo $url | sed -e s,$user@,,g | cut -d/ -f1)
    host="$(echo $hostport | sed -e 's,:.*,,g')"
    port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    path="$(echo $url | grep / | cut -d/ -f2-)"

    printf -- "%s%s=%s\n" "$prefix" "proto" $proto
    printf -- "%s%s=%s\n" "$prefix" "user" $user
    printf -- "%s%s=%s\n" "$prefix" "hostport" $hostport
    printf -- "%s%s=%s\n" "$prefix" "host" $host
    printf -- "%s%s=%s\n" "$prefix" "port" $port
    printf -- "%s%s=%s\n" "$prefix" "path" $path
}

url_encode() {
  local string="${@}"
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
}

function str_join() { 
    local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; 
}

function abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

function repeat_char() {
    local n=$1; ch=$2
    head -c $n < /dev/zero | tr '\0' $ch
}

function if_set() {
    if [[ ! -z "$1" ]] 
    then 
        shift; echo "${@}"
    fi
}

