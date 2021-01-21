#!/bin/bash

# Config provider
# ----------------
# https://config-provider.clicktripz.io/doc

# ----------------------------- 
#            Steps
# -----------------------------
# 1. Create Publisher 
# 2. Create Site
# 3. Create PublisherConfig
# 4. Create VendorSolutionConfig
# 5. Add PublisherMetadataModule to the VendorSolutionConfig
# 6. Set legacyPublisherAlias

# ------------------
# Swagger operations
# ------------------
# = List publishers
#       https://admin.clicktripz.com/api/admin/v1/pms/publisher?afterId=0&limit=200
#
# = Get publisher / organization
#       # https://admin.clicktripz.com/api-docs/index.html#!/PublisherMetadataService/get_admin_v1_pms_publisher
#
# = Delete organization
#       https://admin.clicktripz.com/api-docs/index.html#!/PublisherMetadataService/delete_admin_v1_pms_publisher_organizationId
#
# = Delete site by ID
#       https://admin.clicktripz.com/api-docs/index.html#!/PublisherMetadataService/delete_admin_v1_site_networkId_siteId
#
# = Get site
#       https://admin.clicktripz.com/api-docs/index.html#!/PublisherMetadataService/get_admin_v1_site_networkId


publisher_api="https://admin.clicktripz.com/api/admin/v1/pms/publisher"
site_api="https://admin.clicktripz.com/api/admin/v1/site"
publisher_config_api="https://config-provider.clicktripz.io/v1/AdServices/config/PublisherConfig"
vendor_config_api="https://config-provider.clicktripz.io/v1/AdServices/config/VendorSolutionConfig"

usage ()
{
   printf -- "\n"
   cprintf y "Usage: \n"
   printf -- "  $0 [OPTIONS]\n\n"
   printf -- "Migrate the publisher to PMS\n\n"
   printf -- "Options:\n"
   printf -- "  -a, --alias alias          %s\n" "publisher's legacy alias"
   printf -- "  -d, --domain domain        %s\n" "publisher's domain"
   printf -- "  -s, --session file         %s\n" "path to session file"
   printf -- "  -h, --help                 %s\n" "show help"
   printf -- "  -v, --verbose              %s\n" "verbose mode"
   printf -- "\n"
   exit 1
}

function cprintf() 
{
  local code="\033["
  case "$1" in
    black  | bk) color="${code}0;30m";;
    red    |  r) color="${code}1;31m";;
    green  |  g) color="${code}1;32m";;
    yellow |  y) color="${code}1;33m";;
    blue   |  b) color="${code}1;34m";;
    purple |  p) color="${code}1;35m";;
    cyan   |  c) color="${code}1;36m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac
  [ -z "$text" ] && local text="$color$2${code}0m"
  echo -e "$text"
}


function abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

function get_json_field()
{
    echo "$1" | python3 -c "import sys, json; print(json.load(sys.stdin)$2)"
}

function json_pretty_print() 
{
    echo $1 | python3 -m json.tool
}

function eval_file()
{
    eval $(< $1)
}

function replace_macro()
{
    echo $1 | sed -e "s/\${$2}/$3/" 
}

# Parse the command line parameters
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
      -a|--alias)
      display_name="$2"
      shift
      shift 
      ;;
      -d|--domain)
      site_domain="$2"
      shift
      shift 
      ;;
      -s|--session)
      session_file=$(abs_path $2)
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

if [[ -z ${display_name} ]] 
then
    printf -- "Missing: the display-name is not defined\n"
    usage
fi

if [[ -z ${site_domain} ]] 
then
    printf -- "Missing: the site_domain is not defined\n"
    usage
fi

if [ -f "${session_file}" ]; then
    eval_file "${session_file}"
    session_cookies="PHPSESSID=${PHPSESSID}; AWSALB=${AWSALB}; AWSALBCORS=${AWSALB};"
else 
    printf -- "File doesn't exists: %s\n" ${session_file}
    exit 1
fi

printf -- "Session info:\n"
printf -- "-------------\n"
printf -- "AWSALB     :  %s\n" ${AWSALB}
printf -- "PHPSESSID  :  %s\n" ${PHPSESSID}

#######################
# 1. Create Publisher
#######################
#
# Set displayName equal to "legacy ${integration_group}"
# integration_group is the alias that comes from pageview tracker
#
request="{\"displayName\": \"Legacy ${display_name}\"}"
response=$(curl -s -X POST ${publisher_api} \
    --header "cookie: ${session_cookies}" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    -d "${request}")

cprintf   "Create Publisher request : ${request}" 
cprintf g "Create Publisher response: ${response}" 

status=$(get_json_field "${response}" "['status']")

if [[ "${status}" == "fail" ]]
then
    exit 1
fi

organization_id=$(get_json_field "${response}" "['data']['organizationId']")
 publisher_hash=$(get_json_field "${response}" "['data']['publisherHash']")

cprintf y "Success: organizationId: ${organization_id} publisherHash: ${publisher_hash}"  

#################
# 2. Create Site
#################
#
# Execute a separate request for every domain
# site_name is eTLD+1
#
request="{ \
        \"siteName\": \"${site_domain}\", \
        \"organizationId\": ${organization_id}, \
        \"displayName\": \"${site_domain}\", \
        \"networkId\": \"clicktripz\", \
        \"siteType\": \"app\", \
        \"siteDomains\": [{\"domain\": \"${site_domain}\"}] \
}"

response=$(curl -s -X POST  ${site_api} \
    --header "cookie: ${session_cookies}" \
    --header 'Content-Type: application/json'  \
    --header 'Accept: application/json' \
    -d "${request}")

cprintf   "Create Site request : ${request}" 
cprintf g "Create Site response: ${response}" 

status=$(get_json_field "${response}" "['status']")

if [[ "${status}" == "fail" ]]
then
    exit 1
fi

site_type_0=$(get_json_field "${response}" "['data'][0]['identifiers'][0]['type']")
site_type_1=$(get_json_field "${response}" "['data'][0]['identifiers'][1]['type']")
 site_key_0=$(get_json_field "${response}" "['data'][0]['identifiers'][0]['siteKey']")
 site_key_1=$(get_json_field "${response}" "['data'][0]['identifiers'][1]['siteKey']")
 
 if [[ "${site_type_0}" == "publisherAlias" ]]
 then
    publisher_alias=${site_key_0}
 fi
 if [[ "${site_type_1}" == "publisherAlias" ]]
 then
    publisher_alias=${site_key_1}
 fi

 cprintf y "Success: publisher alias: ${publisher_alias}"
 exit 0

############################
# 3. Create PublisherConfig
############################
#
# Use Shaun's instructions to get ${auth_token}
#
response=$(curl -s -X POST "${publisher_config_api}/${organization_id}" \
  -H "accept: application/json" \
  -H "auth-token: ${auth_token}" \
  -H "Content-Type: application/json" \
  -d "{ \
    '@type': 'PublisherConfig', \
    '@id': '${organization_id}', \
    'serviceModuleConfigs': []}")

#################################
# 4. Create VendorSolutionConfig
#################################
#
# Get the whole document using ${integration_group}
#   $ curl ${vendor_config_api}/{$integration_group}
#   = filter out existing PMS publishers (not like guid_domain or organization_id)
#   = replace the "@id" with ${publisher_alias}
#
response=$(curl -s -X POST "${vendor_config_api}/${publisher_alias}" \
    -H "accept: application/json"  \
    -d "{ \
        '@type': 'VendorSolutionConfig', \
        '@id': '${publisher_alias}', \
        'serviceModuleConfigs': [], \
        'clientModuleConfigs': [] \
    }")

# 5. Add PublisherMetadataModule to the VendorSolutionConfig
#       Shaun will provide instructions for patching VendorSolutionConfig
#     {
#            "@type": "ServiceModuleConfig",
#            "@id": "PublisherMetadataModule",
#            "_enabled": true,
#            "_useResponseEnvelope": true
#    }

# 6. Set legacyPublisherAlias
#
# It should be done manually one-by-one to validate
#