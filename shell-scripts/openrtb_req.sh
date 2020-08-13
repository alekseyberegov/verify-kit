#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo ""
    echo "Usage: $0 [-e|--endpoint <endpoint>] [-h|--help]"
    exit 1
    ;;
    -e|--endpoint)
    endpoint="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# the default bidder endpoint
endpoint=${endpoint:-"http://127.0.0.1:8080"}

proto="$(echo ${endpoint} | grep :// | sed -e's,^\(.*://\).*,\1,g')"
url="$(echo ${endpoint/$proto/})"

# request's headers
hdr_host_name="$(echo ${url} | cut -d/ -f1)"
hdr_cont_type="Content-Type: application/json"
hdr_open_rtb="x-openrtb-version: 2.5"

# payload data
dev_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/80.0 Safari/537.36"
dev_ip="108.185.179.0"
pub_id="100"
pub_cat="[\"sport\", \"coats\", \"spring\"]"
req_id=$(uuidgen)
usr_id=$(uuidgen)

# send the request
echo ""
echo "Sending a bid request to ${endpoint}..."
echo "For more information please use: $0 --help"
echo ""

curl --location  --request POST ${endpoint}  \
  --header "${hdr_cont_type}" \
  --header "${hdr_host_name}" \
  --header "${hdr_open_rtb}" \
  --data-raw "{
      \"id\" : \"${req_id}\",
      \"bcat\" : [],
      \"imp\"   :[{\"id\": \"${req_id}\", \"instl\": 1 }],
      \"site\"  : {\"id\": \"${pub_id}\", \"cat\" : ${pub_cat} },
      \"device\": {\"ua\": \"${dev_ua}\", \"ip\": \"${dev_ip}\" },
      \"user\"  : {\"id\": \"${usr_id}\"}
  }" -w @- <<'EOF'
\n                   ----------\n
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF


