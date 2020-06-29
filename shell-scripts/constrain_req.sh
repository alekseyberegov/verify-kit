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

curl 'https://www.clicktripz.com/api/integrations/v1/constrain?publisherAlias=mapquest&u=https://mapquest.com/' \
  -H 'authority: www.clicktripz.com' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36' \
  -H 'accept: */*' \
  -H 'origin: https://nypost.com' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://nypost.com/' \
  -H 'accept-language: en-US,en;q=0.9,ru;q=0.8' \
  -H "cookie: PHPSESSID=9cba75d4852f8fd8c50f8f92ee7bb677; _ctuid=9d7f20be-088a-4775-b408-d47180b2ecd9;" \
  --compressed