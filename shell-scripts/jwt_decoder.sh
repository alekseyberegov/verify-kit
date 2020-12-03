#!/bin/bash

if [[ -z $1 ]]
then
    printf -- "Usage:\n"
    printf -- "%s JWT_TOKEN\n\n" "$0"
    exit 1
fi

echo "$1" | cut -d"." -f2 | base64 -d
printf -- "\n"


