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
   printf -- "  -s, --settings         print settings\n"
   printf -- "\n"
   exit 1
}

show_settings () {
   printf -- "\n"
   printf -- "%-15s: %s\n" "endpoint" ${constrain_url}
   printf -- "%-15s: %s\n" "site" ${site_name}
   printf -- "%-15s: %s\n" "host" "${page_url_hostport}"
   printf -- "%-15s: %s\n" "origin" "${page_url_proto}/${page_url_hostport}"
   printf -- "%-15s: %s\n" "url" ${page_url}
   printf -- "%-15s: %s\n" "session" ${session_id}
   printf -- "%-15s: %s\n" "user_id" ${user_id}
   printf -- "%-15s: %s\n" "user_agent" "${user_agent}"
   printf -- "%-15s: %s\n" "params" ${constrain_params}
   printf -- "\n"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
   key="$1"

   case $key in
      -h|--help)
      usage
      ;;
      -s|--settings)
      settings="on"
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
   "u=${page_url}" \
   )

if [[ "$settings" == "on" ]]
then
   show_settings
fi

curl "${constrain_url}?${constrain_params}" \
  -H "authority: ${authority_header}" \
  -H "user-agent: ${user_agent}" \
  -H "accept: */*" \
  -H "origin: ${page_url_proto}/${page_url_hostport}" \
  -H "sec-fetch-site: cross-site" \
  -H "sec-fetch-mode: cors" \
  -H "sec-fetch-dest: empty" \
  -H "referer: ${page_url}" \
  -H "accept-language: en-US,en;q=0.9,ru;q=0.8" \
  -H "cookie: PHPSESSID=${session_id}; _ctuid=${user_id};" \
  --compressed
  