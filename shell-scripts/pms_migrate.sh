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
    echo "$1" | python3 -c "import sys, json; print($3(json.load(sys.stdin)$2))"
}

function set_json_field()
{
  echo $1 | python3 -c "import sys, json; o=json.load(sys.stdin); o$2=$3; print(json.dumps(o))"
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

    if [[ "${level}" == "debug" && "${verbose}" != "on" ]]
    then
        return
    fi

     case "${level}" in
        error)
        args="r"
        ;;
        info)
        args="g"
        ;;
        *)
        args=""
        ;;
     esac
    
    for param in "$@"
    do
        cprintf $args "[${FUNCNAME[1]}] ${level}: ${param}" >&2
    done    
}

function check_status()
{
    if [[ $2 == *"status"* ]]; 
    then
        local status=$(get_json_field "$2" "['status']")

        if [[ "${status}" == "success" ]]
        then
            log info "success: $1"
            return
        fi
    fi

    log error "$*"
    exit 1
}

#
# Returns a site key for the given key type
#
# Parameters:
# -----------
# $1 - site key type
# $2 - site object in JSON format
#
function site_key()
{
    local ids_arr="['data'][0]['identifiers']"

    for i in {0..1}; 
    do 
        local key_type=$(get_json_field "$2" "${ids_arr}[$i]['type']")

        if [[ "${key_type}" == "$1" ]]
        then
            local key_value=$(get_json_field "$2" "${ids_arr}[$i]['siteKey']")
        fi
    done
    
    echo "${key_value}"
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

    log debug "$1" "${response}"

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

    log debug "${request}" "${response}"

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

    log debug "${request}" "${response}"

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

    log debug "${request}" "${response}"

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

    log debug "${request}" "${response}"

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

    log debug "${request}" "${response}"

    echo "${response}"
}

#
# Creates VendorSoluionConfig object with the given parameters 
#
# Parameters:
# ------------
# $1 - publisher alias
# $2 - solution config JSON
#
function create_vendor_solution_config()
{
    local auth_token=$(ad_services_auth_token)

    local response=$(curl -s -X POST "${vendor_config_api}/$1" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "$2")

    log debug "$2" "${response}"
    
    echo "${response}"
}

#
# Adds PublisherMetadataModule to a VendorSolutionConfig identified by the publisher alias
#
# Parameters
# ----------
# $1 - publisher alias
# $2 - legacy integration group
#
function update_vendor_solution_config()
{
    local request="{ \
        \"patch\": [ \
            { \
                \"op\": \"add\", \
                \"path\": \"/serviceModuleConfigs/-\", \
                \"value\": { \
                    \"@type\": \"ServiceModuleConfig\", \
                    \"@id\": \"PublisherMetadataModule\", \
                    \"_enabled\": true, \
                    \"_useResponseEnvelope\": true \
                } \
            }, \
            { \
                \"op\" : \"add\", \
                \"path\" : \"/clientModuleConfigs/-\", \
                \"value\" : { \
                    \"@type\": \"ConstrainModule_QueryFirewall2\", \
                    \"@id\": \"query-firewall\", \
                    \"runFor\": \"InlineContext\", \
                    \"firewallAlias\": \"$2\" \
                } \
            } \
        ] \
    }"

    local auth_token=$(ad_services_auth_token)

    local response=$(curl -s -X PATCH "${vendor_config_api}/$1" \
        -H "accept: application/json"  \
        -H "Content-Type: application/json" \
        -H "auth-token: ${auth_token}" \
        -H "Authorization: bearer ${auth_token}" \
        -d "${request}")

    log debug "${request}" "${response}"

    echo "${response}"
}

function send() 
{
    local response=$("$@")
    check_status "$*" "${response}"
    echo "${response}"
} 

function run()
{
    if [ $? -eq 1 ]
    then
        exit 1
    fi

    response="$*"
}

function main()
{
    # Create an authenticated session for PMS
    eval_file "${session_file}"
    session_cookies="PHPSESSID=${PHPSESSID}; AWSALB=${AWSALB}; AWSALBCORS=${AWSALB};"

    # Make sure that none of given domains is already tied to another publisher
    run "$(send pms_sites clicktripz)"
    site_list=$(get_json_field "${response}" "['data']")

    domain_list=$(echo "${site_domains}" | sed "s/,/ /g")
    for domain in ${domain_list}
    do
        if [[ "${site_list}" == *"${domain}"* ]]
        then
            log error "The domain ${domain} is already used by another organization"
            exit 1
        fi
    done

    # Get VendorSolutionConfig for the integration group
    run "$(send vendor_solution_config ${integration_group})"
    solution_config=$(get_json_field "${response}" "['data']['config']" "json.dumps")
  
    # Create Publisher
    run "$(send create_pms_publisher ${integration_group})"
    organization_id=$(get_json_field "${response}" "['data']['organizationId']")

    # Verify publisher
    run "$(send verify_pms_publisher ${organization_id})"

    # Create PublisherConfig
    run "$(send create_publisher_config ${organization_id})"

    # Create Site and VendorSolutionConfig for each domain (eTLD+1)
    for domain in $domain_list
    do
        # Create Site
        run "$(send create_pms_site ${organization_id} ${domain})"

        # Get site's fields
        site_id=$(get_json_field "${response}" "['data'][0]['id']")
        site_alias=$(site_key publisherAlias "${response}")
        site_config=$(set_json_field "${solution_config}" "['@id']" "'${site_alias}'")

        # Verify Site
        run "$(send verify_pms_site clicktripz ${site_id} ${domain})"

        # Create VendorSolutionConfig and patch it with PublisherMetadataModule
        run $(send create_vendor_solution_config ${site_alias} "${site_config}")
        run $(send update_vendor_solution_config ${site_alias} ${integration_group})
    done
}

function parse_args()
{
     unknown_args=()

    # Parse the command line parameters
    while [[ $# -gt 0 ]]
    do
        case $1 in
            -h|--help)
                usage
            ;;
            -v|--verbose)
                verbose="on"
            ;;
            -a|--alias)
                integration_group="$2"
                shift
            ;;
            -d|--domain)
                site_domains="$2"
                shift
            ;;
            -s|--session)
                session_file=$(abs_path $2)
                shift
            ;;
            *)
                unknown_args+=("$1") 
            ;;
        esac
        shift
    done
    set -- "${unknown_args[@]}"
}

function validate_args()
{
    if [[ -z ${integration_group} ]] 
    then
        log error "The alias is not specified"
        usage
    fi

    if [[ -z ${site_domains} ]] 
    then
        log error "Publisher's domains are not specified"
        usage
    fi

    if [ ! -f "${session_file}" ]; then
        log error "File doesn't exists: \"${session_file}\""
        usage
    fi
}

# =======================================================
#                      ENTRY POINT
# =======================================================
parse_args "$@"
validate_args
main

