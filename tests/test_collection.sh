#!/bin/bash

. $(dirname "$0")/../shell-scripts/functions/base.sh
. $(dirname "$0")/../shell-scripts/functions/collection.sh

declare -a req_params=( \
   "optMaxAdvertisers=7" \
   "optRotationStrategy=1" \
   "optPopUnder=1" \
   "optLocalization=en" \
   "tabbedMode=1" \
   "userForcedTabbedMode=1" \
   "callback=jsonp_func"  \
   "obj=exit_unit" \
)

d="&"
result=$(printf -- "%s" "${req_params[@]/,/$d}")
echo $result
printf -- "\n"
array_join $d req_params