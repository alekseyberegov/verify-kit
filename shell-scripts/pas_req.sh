#/bin/bash

. $(dirname "$0")/functions/base.sh
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


print_params () {
   declare -a nv=( \
      "endpoint=${pas_url}" \
      "site=${site_name}" \
      "host=${page_url_hostport}" \
      "placement_id=${placement_id}" \
      "url=${page_url}" \
      "audiences=${audiences}" \
      "user_id=${user_id}" \
      "user_agent=${user_agent}" \
      "destination=${destination}" \
      "params=${pas_params}" \
   )

   print_nvc nv
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

pas_params=$(str_join "&"  \
   "ctzpid=$(uuidgen)" \
   "alias=${site_name}" \
   "siteId=${site_name}" \
   "placementId=${placement_id}" \
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

if [[ "$verbose" == "on" ]]
then
   print_params
fi

printf -- "%-14s-> %s\n" "request" "${pas_url}?${pas_params}"
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

