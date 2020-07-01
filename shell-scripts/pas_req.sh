#/bin/bash

. $(dirname "$0")/functions/base.sh
. $(dirname "$0")/functions/yaml-parser.sh

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


show_settings () {
    local ch='-'

    printf -- "\n"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    printf -- "| %-12s| %-64s|\n" "Name" "Value"
    printf -- "+-------------+%s+\n" "$(repeat_char 65 $ch)"
    printf -- "| %-12s: %-64s|\n" "endpoint" ${pas_url}
    printf -- "| %-12s: %-64s|\n" "site" ${site_name}
    printf -- "| %-12s: %-64s|\n" "host" "${page_url_hostport}"
    printf -- "| %-12s: %-64s|\n" "placement_id" "${placement_id}"
    printf -- "| %-12s: %-64s|\n" "url" ${page_url}
    printf -- "| %-12s: %-64s|\n" "audiences" ${audiences}
    printf -- "| %-12s: %-64s|\n" "user_id" ${user_id}
    printf -- "| %-12s: %-64s|\n" "user_agent" "${user_agent}"
    printf -- "| %-12s: %-64s|\n" "destination" "${destination}"
    printf -- "| %-12s: %-64s|\n" "params" ${pas_params}
    printf -- "+-------------+%s+\n\n" "$(repeat_char 65 $ch)"
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

if [[ $config_file == "" ]]
then
   usage
fi

pas_req=$(abs_path $config_file)

eval $(parse_yaml ${pas_req})
eval $(parse_url ${page_url} "page_url_")

pas_params=$(join_by "&"  \
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
   show_settings
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

