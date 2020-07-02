#!/bin/bash

foreach () { 
    arr="$(declare -p $1)" ; eval "declare -a f="${arr#*=};     
    for i in ${!f[@]}; do $2 "$i" "${f[$i]}"; done
}

function array_join() {
    local d=$1; 
    arr="$(declare -p $2)" ; eval "declare -a f="${arr#*=};    
    printf "%s" "${f[@]/#/$d}" 
}