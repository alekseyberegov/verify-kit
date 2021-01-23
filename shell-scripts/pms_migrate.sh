#!/bin/bash

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
    white  |  w) color="${code}1m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac
  [ -z "$text" ] && local text="$color$2${code}0m"
  echo -e "$text"
}

usage ()
{
   printf -- "\n"
   cprintf w "Usage: \n"
   cprintf w "  $0 [OPTIONS]\n\n"
   printf -- "Migrate the publisher to PMS\n\n"
   printf -- "Options:\n"
   printf -- "  -a, --alias alias          %s\n" "publisher's legacy alias"
   printf -- "  -d, --domain domains       %s\n" "publisher's comma-separated domains"
   printf -- "  -s, --session file         %s\n" "path to session file"
   printf -- "  -h, --help                 %s\n" "show help"
   printf -- "  -v, --verbose              %s\n" "verbose mode"
   printf -- "\nExample:\n"
   printf -- "      $0 -a nypost -d \"nypost.com,pagesix.com\" -s ~/pms_session.env\n"
   printf -- "\n"
   exit 1
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
#
# Logs specified input arguments
#
# Parameters:
# -----------
# $1 - level (info|debug|error)
# .. - arguments to be logged
#
function log()
{
    local level=$1; shift
    
    for param in "$@"
    do
        cprintf  "${level}: ${FUNCNAME[1]} ${param}" >&2
    done    
}

function check_status()
{
    if [[ $2 == *"status"* ]]; 
    then
        local status=$(get_json_field "$2" "['status']")

        if [[ "${status}" == "success" ]]
        then
            cprintf g "Success: $1\n" >&2
            return
        fi
    fi

    cprintf r "Error: $1 $2\n" >&2
    exit 1
}


function parse_publisher_alias()
{
    for i in {0..1}; 
    do 
        local key_type=$(get_json_field "$1" "['data'][0]['identifiers'][$i]['type']")

        if [[ "${key_type}" == "publisherAlias" ]]
        then
            local publisher_alias=$(get_json_field "$1" "['data'][0]['identifiers'][$i]['siteKey']")
        fi
    done
    
    echo "${publisher_alias}"
}

#
# Generates an authentication token
#
function ad_services_auth_token()
{
    local response=$(curl -s -X POST "${ad_services_token_api}" -H "accept: application/json")
    echo $(get_json_field "${response}" "['data']['auth-token']")
}

#
# Returns a list of PMS sites
#
# Parameters:
# ----------
# $1 - network id
#
function pms_sites()
{
    local response=$(curl -s -X GET "${site_api}/$1" \
        --header "cookie: ${session_cookies}" \
        --header 'Accept: application/json')

    echo "${response}"
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
    local auth_token=$(ad_services_auth_token)

    local response=$(curl -s "${vendor_config_api}/$1" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -H "accept: application/json")

    log info "$1" "${response}"

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
    local request="{\"displayName\": \"Legacy ${1}\"}"

    local response=$(curl -s -X POST ${publisher_api} \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -d "${request}")

    log info "${request}" "${response}"

    echo "${response}"
}

#
# Verifies the given PMS publisher
#
# Parameters:
# -----------
# $1 - organization_id
#
function verify_pms_publisher()
{
    local request="{\"isVerified\": true}"

    local response=$(curl -s -X PUT "${publisher_api}/$1" \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -d "${request}")

    log info "${request}" "${response}"

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
    local request="{ \
        \"siteName\": \"$2\", \
        \"organizationId\": $1, \
        \"displayName\": \"$2\", \
        \"networkId\": \"clicktripz\", \
        \"siteType\": \"app\", \
        \"siteDomains\": [{\"domain\": \"$2\"}] \
    }"

    local response=$(curl -s -X POST  ${site_api} \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json'  \
        --header 'Accept: application/json' \
        -d "${request}")

    log info "${request}" "${response}"

    echo "${response}"
}

#
# Verifies the given PMS site
#
# Parameters:
# ------------
# $1 - network id
# $2 - site id
# $3 - domain name
#
function verify_pms_site()
{
    local request="{\"siteDomains\": [ {\"domain\": \"$3\", \"isVerified\": true} ]}"

    local response=$(curl -s -X PUT "${site_api}/$1/$2" \
        --header "cookie: ${session_cookies}" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -d "${request}")

    log info "${request}" "${response}"

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
    local auth_token=$(ad_services_auth_token)

    local request="{ \
        \"@type\":\"PublisherConfig\", \
        \"@id\": \"$1\", \
        \"serviceModuleConfigs\": [] \
    }"

    local params=(-s -L -X POST "${publisher_config_api}/$1" \
        -H "accept: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -H "Content-Type: application/json" \
        -d "${request}")

    local response=$(curl "${params[@]}")

    log info "${request}" "${response}"

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
    local auth_token=$(ad_services_auth_token)

    local response=$(curl -s -X POST "${vendor_config_api}/$2" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "$1")

    log info "$1" "${response}"
    
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
    local request="{ \
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

    local auth_token=$(ad_services_auth_token)

    local response=$(curl -s -X PATCH "${vendor_config_api}/$1" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "${request}")

    log info "${request}" "${response}"

    echo "${response}"
}

function send() 
{
    local response=$("$@")
    check_status "$*" "${response}"
    echo "${response}"
} 

function main()
{
    # Make sure that none of given domains is already tied to another publisher
    response=$(send pms_sites clicktripz)
    site_list=$(get_json_field "${response}" "['data']")

    for domain in $(echo "${site_domains}" | sed "s/,/ /g")
    do
        if [[ "${site_list}" == *"${domain}"* ]]
        then
            cprintf b "${site_list}\n"
            cprintf r "Error:  The domain ${domain} is already used by another organization\n"
            exit 1
        fi
    done

    # Get VendorSolutionConfig for the integration group
    solution_config=$(send vendor_solution_config "${integration_group}")

    # Create Publisher
    response=$(send create_pms_publisher "${integration_group}")
    organization_id=$(get_json_field "${response}" "['data']['organizationId']")

    # Verify publisher
    response=$(send verify_pms_publisher "${organization_id}")

    # Create PublisherConfig
    response=$(send create_publisher_config "${organization_id}")

    # Create Site and VendorSolutionConfig for each domain (eTLD+1)
    for domain in $(echo ${site_domains} | sed "s/,/ /g")
    do
        # Create Site
        response=$(send create_pms_site ${organization_id} "${domain}")
        site_id=$(get_json_field "${response}" "['data'][0]['id']")
        publisher_alias=$(parse_publisher_alias "${response}")

        # Verify Site
        response=$(send verify_pms_site clicktripz ${site_id} "${domain}")

        # Create VendorSolutionConfig
        conf_object=$(echo ${solution_config} \
                | python3 -c "import sys, json; d=(json.load(sys.stdin)['data']['config']); d['@id']='${publisher_alias}'; print(json.dumps(d))")
        response=$(send create_vendor_solution_config "${conf_object}" "${publisher_alias}")

        # Patch VendorSolutionConfig with PublisherMetadataModule
        response=$(send patch_vendor_solution_config "${publisher_alias}")
    done
}

function parse_args()
{
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
        site_domains="$2"
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
        cprintf r "Error: the alias is not specified\n"
        usage
    fi

    if [[ -z ${site_domains} ]] 
    then
        cprintf r "Error: publisher's domains are not specified\n"
        usage
    fi

    if [ -f "${session_file}" ]; then
        eval_file "${session_file}"
        session_cookies="PHPSESSID=${PHPSESSID}; AWSALB=${AWSALB}; AWSALBCORS=${AWSALB};"
    else 
        cprintf r "Error: File doesn't exists: ${session_file}\n"
        exit 1
    fi
}

parse_args "$@"
main

