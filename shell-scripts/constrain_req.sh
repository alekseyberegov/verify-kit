#/bin/bash

. $(dirname "$0")/functions/base.sh
. $(dirname "$0")/functions/yaml-parser.sh
. $(dirname "$0")/functions/prettyprint.sh

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
     declare -a nv=( \
      "endpoint=${constrain_url}" \
      "site=${site_name}" \
      "host=${page_url_hostport}" \
      "origin=${page_url_proto}${page_url_hostport}" \
      "url=${page_url}" \
      "session=${session_id}" \
      "user_id=${user_id}" \
      "user_agent=${user_agent}" \
      "params=${constrain_params}" \
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

constrain_params=$(str_join "&"  \
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