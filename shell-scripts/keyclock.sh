#!/bin/bash

# if [ $# -ne 5 ]; then
#   printf -- "Usage: . $0 hostport realm username client_id\n"
#   printf --  "  options:\n"
#   printf --  "    hostport  - host:port\n"
#   printf --  "    realm     - keycloak realm\n"
#   printf --  "    client_id - client\n"
#   printf --  "    For verify ssl: use 'y' (otherwise it will send curl post with --insecure)\n\n"
  
#   exit 1
# fi

HOSTNAME=prod-keycloak.cubaneddie.k8s.clicktripz.io
REALM_NAME="ctz-internal"
USERNAME="aleksey@clicktripz"
#CLIENT_ID="config-provider-prod"
CLIENT_ID="admin-cli"
SECURE=y

# prod-keycloak.cubaneddie.k8s.clicktripz.io
# config-provider-prod
# ctz-internal
#
# KEYCLOAK_URL=https://$HOSTNAME/auth/realms/$REALM_NAME/protocol/openid-connect/token
# https://prod-keycloak.cubaneddie.k8s.clicktripz.io/auth/realms/ctz-internal/.well-known/openid-configuration


KEYCLOAK_URL="https://prod-keycloak.cubaneddie.k8s.clicktripz.io/auth/realms/ctz-internal/protocol/openid-connect/token"

echo "Using Keycloak: $KEYCLOAK_URL"
echo "realm: $REALM_NAME"
echo "client-id: $CLIENT_ID"
echo "username: $USERNAME"
echo "secure: $SECURE"


if [[ $SECURE = 'y' ]]; then
	INSECURE=
else 
	INSECURE=--insecure
fi


echo -n Password: 
read -s PASSWORD

response=$(curl -i -X POST "${KEYCLOAK_URL}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}" \
  -d "client_id=${CLIENT_ID}" \
)


echo "${response}"

# if [[ $(echo $TOKEN) != 'null' ]]; then
# 	export KEYCLOAK_TOKEN=$TOKEN
# fi


# export access_token=$(\
#     curl --insecure -X POST https://localhost:8543/auth/realms/quarkus/protocol/openid-connect/token \
#     --user backend-service:secret \
#     -H 'content-type: application/x-www-form-urlencoded' \
#     -d 'username=alice&password=alice&grant_type=password' | jq --raw-output '.access_token' \
#  )