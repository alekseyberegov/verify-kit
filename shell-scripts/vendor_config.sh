#!/bin/bash

function stacktrace { 
   local i=1
   while caller $i | read line func file; do 
      echodbg "[$i] $file:$line $func()"
      ((i++))
   done
}


stacktrace

curl -s "http://localhost:8081/v1/AdServices/config/VendorSolutionConfig/$1" \
 | python3 -c "import sys, json; d=(json.load(sys.stdin)['data']['config']); d['@id']='$2'; print(json.dumps(d))" \
