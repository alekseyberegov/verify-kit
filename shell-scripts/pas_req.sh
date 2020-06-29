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
   printf -- "  -r, --request file     specify config for the request\n"
   printf -- "  -h, --help             show help\n"
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
   )

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

