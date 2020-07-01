#/bin/bash

. $(dirname "$0")/functions/base.sh
. $(dirname "$0")/functions/yaml-parser.sh

usage ()
{
   printf -- "\n"
   printf -- "Usage: \n"
   printf -- "  $0 [OPTIONS]\n\n"
   printf -- "Send request to CONSTRAIN\n\n"
   printf -- "Options:\n"
   printf -- "  -r, --request file     specify config for the request\n"
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
    printf -- "| %-12s: %-64s|\n" "endpoint" ${constrain_url}
    printf -- "| %-12s: %-64s|\n" "site" ${site_name}
    printf -- "| %-12s: %-64s|\n" "host" "${page_url_hostport}"
    printf -- "| %-12s: %-64s|\n" "origin" "${page_url_proto}${page_url_hostport}"
    printf -- "| %-12s: %-64s|\n" "url" ${page_url}
    printf -- "| %-12s: %-64s|\n" "session" ${session_id}
    printf -- "| %-12s: %-64s|\n" "user_id" ${user_id}
    printf -- "| %-12s: %-64s|\n" "user_agent" "${user_agent}"
    printf -- "| %-12s: %-64s|\n" "params" ${constrain_params}
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

constrain_params=$(join_by "&"  \
   "publisherAlias=${site_name}" \
   "u=$(url_encode ${page_url})" \
   "_ctuid=${user_id}" \
   )

if [[ "$verbose" == "on" ]]
then
   show_settings
fi

printf -- "%-14s-> %s\n" "request" "${constrain_url}?${constrain_params}"
printf -- "%-14s<- " "response"

curl "${constrain_url}?${constrain_params}" \
  -H "authority: ${authority_header}" \
  -H "user-agent: ${user_agent}" \
  -H "accept: */*" \
  -H "origin: ${page_url_proto}${page_url_hostport}" \
  -H "sec-fetch-site: cross-site" \
  -H "sec-fetch-mode: cors" \
  -H "sec-fetch-dest: empty" \
  -H "referer: ${page_url}" \
  -H "accept-language: en-US,en;q=0.9,ru;q=0.8" \
  -H "cookie: PHPSESSID=${session_id}; _ctuid=${user_id};" \
  --compressed

printf -- "\n\n"