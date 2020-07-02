#!/bin/bash

. $(dirname "$0")/../shell-scripts/functions/base.sh
. $(dirname "$0")/../shell-scripts/functions/collection.sh
. $(dirname "$0")/../shell-scripts/functions/prettyprint.sh

declare -a nv=("n10=10" "n200=200" "n3000=3000")

print_item() { printf -- "%s -> %s\n" "$1" "$2"; }

foreach nv print_item

print_nvc nv

