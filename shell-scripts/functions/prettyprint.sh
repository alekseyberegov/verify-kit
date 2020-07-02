#!/bin/bash

function print_hr() {
    printf -- "+%s+%s+\n" "$(repeat_char $2 $1)" "$(repeat_char $3 $1)"
}

function print_nvc() {
    local ch='-'; local w0=20; local w1=$((80 - 3 - w0));
    local a; local v; local l; local i
    local nv="$(declare -p $1)" ; eval "declare -a k="${nv#*=};

    printf -- "\n"
    print_hr $ch $w0 $w1
    printf -- "|%${w0}s|%-${w1}s|\n" "NAME" "VALUE"
    print_hr $ch $w0 $w1

    for i in ${!k[@]} 
    do
        a=(${k[$i]/=/ }); v="${a[@]:1}"; l=${#v}
        for ((i = 0 ; i < l ; i += w1)) ; do
            printf -- "|%${w0}s|%-${w1}s|\n" "${a[0]}" "${v:i:w1}"
        done
    done

    print_hr $ch $w0 $w1
}



