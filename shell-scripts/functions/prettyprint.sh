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
    local ch='-'
    local nv="$(declare -p $1)" ; eval "declare -a k="${nv#*=};
    local a; v

    printf -- "\n"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    printf -- "| %-12s| %-64s|\n" "Name" "Value"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    for i in ${!k[@]} 
    do
        a=(${k[$i]/=/ })
        v="${a[@]:1}"
        printf -- "| %-12s: %-64s|\n" "${a[0]}" "$v"
    done
    printf -- "+-------------+%s+\n\n" "$(repeat_char 65 $ch)"
}



