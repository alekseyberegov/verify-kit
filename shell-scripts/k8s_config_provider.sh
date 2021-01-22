#!/bin/bash

trap ctrl_c INT

function ctrl_c() 
{
    printf -- "Killing keep-alive PID=%d\n" $pid
    kill $pid >/dev/null 2>&1
}

function keep_alive()
{
    while true ; do nc -vz 127.0.0.1 8081 ; sleep 30 ; done
}

if [[ "$1" != "prod" && "$1" != "staging" ]]; then
    printf -- "Usage: $0 (prod|staging)\n"
    exit 1
fi

keep_alive &
pid=$!

printf -- "The keep-alive PID=%d\n" $pid

kubectl port-forward svc/config-provider 8081:80 -n "$1-bac"






