#/bin/bash

. $(dirname "$0")/functions/base.sh
. $(dirname "$0")/functions/collection.sh
. $(dirname "$0")/functions/yaml-parser.sh
. $(dirname "$0")/functions/prettyprint.sh

usage ()
{
   printf -- "\n"
   printf -- "Usage: \n"
   printf -- "  $0 [OPTIONS]\n\n"
   printf -- "Send request to PAS\n\n"
   printf -- "Options:\n"
   printf -- "  -r, --request file     request configuratio file\n"
   printf -- "  -h, --help             show help\n"
   printf -- "  -v, --verbose          verbose mode\n"
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
      -v|--verbose)
      verbose="on"
      shift
      ;;
      -r|--request)
      config_file="$2"
      pas_req=$(abs_path $config_file)
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

if [[ -z $config_file ]]
then
   usage
fi

eval $(parse_yaml ${pas_req})
eval $(parse_url ${page_url} "page_url_")

declare -a req_params=( \
   "ctzpid=$(uuidgen)" \
   "alias=${site_name}" \
   "siteId=${site_name}" \
   "aid=${aid}" \
   "siteId=${siteId}" \
   "publisherHash=${publisherHash}" \
   "audiences=$(url_encode $audiences)" \
   "ref=$(url_encode $page_url)" \
   "optMaxChecked=2" \
   "optMaxAdvertisers=7" \
   "optRotationStrategy=1" \
   "optPopUnder=1" \
   "optLocalization=en" \
   "tabbedMode=1" \
   "userForcedTabbedMode=1" \
   "callback=jsonp_func" \
   "obj=exit_unit" \
   $(if_set "${destination}" "destination=$(url_encode ${destination})") \
   $(if_set "${origin}" "origin=${origin}") \
   $(if_set "${startDate}" "startDate=$(url_encode ${startDate})") \
   $(if_set "${endDate}" "endDate=$(url_encode ${endDate})") \
   $(if_set "${adults}" "adults=${adults}") \
   $(if_set "${isOneWay}" "isOneWay=${isOneWay}") \
   )

pas_params=$(array_join "&" req_params)

if [[ "$verbose" == "on" ]]
then
   declare -a req_props=( \
      "endpoint=${pas_url}" \
      "host=${page_url_hostport}" \
      "url=${page_url}" \
      "user_id=${user_id}" \
      "user_agent=${user_agent}" \
      "params=${pas_params}" \
   )

   print_nvc req_params
   print_nvc req_props
fi

printf -- "%-14s-> %s\n" "request" "${pas_url}?qa=true${pas_params}"
printf -- "%-14s<- " "response"

curl  "${pas_url}?${pas_params}" \
  -H "authority:${page_url_hostport}" \
  -H "user-agent: ${user_agent}" \
  -H 'accept: */*' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: no-cors' \
  -H 'sec-fetch-dest: script' \
  -H "referer: ${page_url}" \
  -H 'accept-language: en-US,en;q=0.9,ru;q=0.8' \
  -H "cookie: _ctuid=${user_id};" \
  --compressed

