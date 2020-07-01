#!/bin/bash

. $(dirname "$0")/../shell-scripts/functions/base.sh
. $(dirname "$0")/../shell-scripts/functions/prettyprint.sh

print_item() { echo "$1 -> $2"; }

declare -a names=("n10" "n200" "n3000" "n40000" "n500000" "n60" "n700" "n8000" "n90000" "n100000")
declare -a values=(10 200 3000 40000 500000 60 700 8000 90000 100000)
declare -a nv=("n10=10" "n200=200" "n3000=3000")

foreach names print_item
foreach values print_item

print_nv names values 
print_nvc nv

