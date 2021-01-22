#!/bin/bash

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
# = Config provider operations
#       https://config-provider.clicktripz.io/doc
#
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


# Staging PMS endpoints
# ---------------------
# publisher_api="https://staging.clicktripz.com/api/admin/v1/pms/publisher"
# site_api="https://staging.clicktripz.com/api/admin/v1/site"

# Production PMS endpoints
# -------------------------
publisher_api="https://admin.clicktripz.com/api/admin/v1/pms/publisher"
site_api="https://admin.clicktripz.com/api/admin/v1/site"

# Proxied ConfigProvider endpoints
# ---------------------------------
publisher_config_api="http://localhost:8081/v1/AdServices/config/PublisherConfig"
vendor_config_api="http://localhost:8081/v1/AdServices/config/VendorSolutionConfig"
ad_services_token_api="http://localhost:8081/v1/AdServices/credentials"


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

function out()
{
    s="'$*'"
    printf -- "$s"
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

function log_msg_exchange()
{
    cprintf   "$1 << $2" >&2
    cprintf b "$1 >> $3" >&2
}

function check_response_status()
{
    status=$(get_json_field "$2" "['status']")

    if [[ "${status}" == "fail" ]]
    then
        cprintf r "Error: $1 $2" >&2
        exit 1
    else 
        cprintf g "Success: $1\n" >&2
    fi
}

############################################################################################

#
# Generates an authentication token
#
function ad_services_auth_token()
{
    response=$(curl -s -X POST "${ad_services_token_api}" -H "accept: application/json")
    echo $(get_json_field "${response}" "['data']['auth-token']")
}

#
# Gets the VendorSolutionConfig object for the given integration group
#
# Parameters:
# ------------
# $1 - integration group (old alias)
#
function vendor_solution_config()
{
    auth_token=$(ad_services_auth_token)

    response=$(curl -s "${vendor_config_api}/$1" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -H "accept: application/json")

    log_msg_exchange "VendorSolutionConfig" "$1" "${response}"

    echo "${response}"
}

#
# Creates PMS Publisher object with the given parameters
#
# Parameters:
# ------------
# $1 - the integration group (old alias)
#
function create_pms_publisher()
{
    request="{\"displayName\": \"Legacy ${1}\"}"

    response=$(curl -s -X POST ${publisher_api} \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -d "${request}")

    log_msg_exchange "PMS publisher" "${request}" "${response}"

    echo "${response}"
}

#
# Creates PMS Site object with the given parameters
#
# Parameters:
# -----------
# $1 - organizationId
# $2 - domain
#
function create_pms_site()
{
    request="{ \
        \"siteName\": \"$2\", \
        \"organizationId\": $1, \
        \"displayName\": \"$2\", \
        \"networkId\": \"clicktripz\", \
        \"siteType\": \"app\", \
        \"siteDomains\": [{\"domain\": \"$2\"}] \
    }"

    response=$(curl -s -X POST  ${site_api} \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json'  \
        --header 'Accept: application/json' \
        -d "${request}")

    log_msg_exchange "PMS site" "${request}" "${response}"

    echo "${response}"
}

#
# Creates PublisherConfig object with the given parameters
#
# Parameters:
# ------------
# $1 - integration group (old alias)
#
function create_publisher_config()
{
    auth_token=$(ad_services_auth_token)

    request="{ \
        \"@type\":\"PublisherConfig\", \
        \"@id\": \"$1\", \
        \"serviceModuleConfigs\": [] \
    }"

    params=(-s -L -X POST "${publisher_config_api}/$1" \
        -H "accept: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -H "Content-Type: application/json" \
        -d "${request}")

    response=$(curl "${params[@]}")

    log_msg_exchange "PublisherConfig" "${request}" "${response}"

    echo "${response}"
}

#
# Creates VendorSoluionConfig object with the given parameters 
#
# Parameters:
# ------------
# $1 - integration group (old alias)
# $2 - publisher alias
#
function create_vendor_solution_config()
{
    auth_token=$(ad_services_auth_token)

    response=$(curl -s -X POST "${vendor_config_api}/$2" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "$1")

    log_msg_exchange "VendorSolutionConfig" "$1" "${response}"
    
    echo "${response}"
}

#
# Adds PublisherMetadataModule to a VendorSolutionConfig identified by the publisher alias
#
# Parameters
# $1 - publisher alias
#
function patch_vendor_solution_config()
{
    request="{ \
        \"patch\": [{ \
                \"op\": \"add\", \
                \"path\": \"/serviceModuleConfigs/-\", \
                \"value\": { \
                    \"@type\": \"ServiceModuleConfig\", \
                    \"@id\": \"PublisherMetadataModule\", \
                    \"_enabled\": true, \
                    \"_useResponseEnvelope\": true \
                } \
            }] \
    }"

    auth_token=$(ad_services_auth_token)

    response=$(curl -s -X PATCH "${vendor_config_api}/$1" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "${request}")

    log_msg_exchange "VendorSolutionConfig-patch" "${request}" "${response}"

    echo "${response}"
}
############################################################################################

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
      integration_group="$2"
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

if [[ -z ${integration_group} ]] 
then
    printf -- "Missing: the alias is not defined\n"
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

# =============================================================================
# 0. Get VendorSolutionConfig for the integration group
# =============================================================================
solution_config=$(vendor_solution_config "${integration_group}")
check_response_status "VendorSolutionConfig" "${solution_config}"

# =============================================================================
# 1. Create Publisher
# =============================================================================
response=$(create_pms_publisher "${integration_group}")
check_response_status "PMS publisher" "${response}"

organization_id=$(get_json_field "${response}" "['data']['organizationId']")
 publisher_hash=$(get_json_field "${response}" "['data']['publisherHash']")

# =============================================================================
# 2. Create Site
# =============================================================================
#
# Execute a separate request for every domain (eTLD+1)
#
response=$(create_pms_site ${organization_id} "${site_domain}")
check_response_status "PMS site" "${response}"

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

# =============================================================================
# 3. Create PublisherConfig
# =============================================================================
response=$(create_publisher_config "${organization_id}")
check_response_status "PublisherConfig" "${response}"

# =============================================================================
# 4. Create VendorSolutionConfig
# =============================================================================
#
solution_config=$(echo ${solution_config} \
        | python3 -c "import sys, json; d=(json.load(sys.stdin)['data']['config']); d['@id']='${publisher_alias}'; print(json.dumps(d))")

response=$(create_vendor_solution_config "${solution_config}" "${publisher_alias}")
check_response_status "VendorSolutionConfig" "${response}"

# =============================================================================
# 5. Patch VendorSolutionConfig with PublisherMetadataModule
# =============================================================================
response=$(patch_vendor_solution_config "${publisher_alias}")
check_response_status "VendorSolutionConfig-patch" "${response}"
