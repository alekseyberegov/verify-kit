#!/bin/bash

function print_nv() {
    local ch='-'
    local names="$(declare -p $1)" ; eval "declare -a k="${names#*=};     
    local values="$(declare -p $2)" ; eval "declare -a v="${values#*=};  

    printf -- "\n"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    printf -- "| %-12s| %-64s|\n" "Name" "Value"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    for i in ${!k[@]} 
    do
        printf -- "| %-12s: %-64s|\n" "${k[$i]}" "${v[$i]}"
    done
    printf -- "+-------------+%s+\n\n" "$(repeat_char 65 $ch)"
}


function print_nvc() {
    local ch='-'; local a; local v; local l; local i
    local nv="$(declare -p $1)" ; eval "declare -a k="${nv#*=};

    printf -- "\n"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    printf -- "| %-12s| %-64s|\n" "Name" "Value"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    for i in ${!k[@]} 
    do
        a=(${k[$i]/=/ })
        v="${a[@]:1}"
        l=${#v}
        i=0
        printf -- "| %-12s: %-64s|\n" "${a[0]}" "${v:0:64}"
        while : ; do
        i="$(($i + 64))"
            [[ i -lt l ]] || break
            printf -- "| %-12s: %-64s|\n" " " "${v:i:64}"
        done
    done
    printf -- "+-------------+%s+\n\n" "$(repeat_char 65 $ch)"
}



