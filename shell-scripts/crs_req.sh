#!/bin/bash
# 
# You need to have access to a k8s cluster
# $ kubectl port-forward svc/creative-resolution 8080:80 -n prod-bac

sample_size=100
temp_file=$(mktemp)
publisher_id="3158"
experiment_name="crs_split_test"

usage ()
{
   printf -- "\n"
   printf -- "Usage: \n"
   printf -- "  $0 [OPTIONS]\n\n"
   printf -- "Send request to CRS\n\n"
   printf -- "Options:\n"
   printf -- "  -s, --size          the sample size\n"
   printf -- "  -e, --experiment    the experiment name\n"
   printf -- "  -p, --publisher_id  the publisher ID\n"
   printf -- "  -h, --help          show help\n"
   printf -- "\n"
   exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
   key="$1"

   case $key in
      -h|--help)
      usage
      ;;
      -s|--size)
      sample_size=$2
      shift
      shift 
      ;;
      -e|--experiment)
      experiment_name=$2
      shift
      shift 
      ;;
      -p|--publisher_id)
      publisher_id=$2
      shift
      shift 
      ;;
      *)
      POSITIONAL+=("$1") 
      shift 
      ;;
   esac
done
set -- "${POSITIONAL[@]}"

printf -- "Sending %d requests for %s\n" ${sample_size} ${experiment_name}
printf -- "Using %s \n" ${temp_file}

for i in $(seq 1 ${sample_size});
do
    user_id=$(uuidgen)

    curl -s -X POST "http://localhost:8080/api/v1/resolve" \
        -H "accept: application/json" \
        -H "Content-Type: application/json" \
        -H "cookie: _ctuid=${user_id};" \
        -d "{ \"publisher_id\": \"${publisher_id}\", \"experiment\": { \"experiment\": \"${experiment_name}\"}}" | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['data']['creative_id'])" >> ${temp_file}
done

close_cnt=$(grep "close-creative" ${temp_file} | wc -l)
printf -- "%s from %s are no-show creatives, percentage = %s%%\n" \
    ${close_cnt} ${sample_size}  $(echo "scale=2 ; 100 * ${close_cnt} / ${sample_size}" | bc) 

rm ${temp_file}