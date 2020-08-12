#!/bin/bash

# https://admin.clicktripz.com/api/admin/v1/advertiser/audience/pricing?advertiserId=462
# https://admin.clicktripz.com/api/rte/v1/users/d83dc1ae-0126-47ac-9231-11aed27c6ba7/profile?advertisers=462


ape_service="https://localhost:8888/v1/audience_pricing"

curl -k --request POST ${ape_service}  \
    -H "Host: prod-ds-machine-learning.cubaneddie.k8s.clicktripz.io" \
    --data-raw "{
        \"currentTimestamp\": 1597159444,
        \"audiences\"       : {\"typeOne\": [\"21\"]},
        \"alias\"           : \"mapquest\",
        \"deviceID\"        : 101,
        \"deviceName\"      : \"Desktop\",
        \"browserID\"       : 1,
        \"browserName\"     : \"Chrome\",
        \"ctzUserID\"       : \"d83dc1ae-0126-47ac-9231-11aed27c6ba7\",
        \"profile\"         : {
            \"advertisers\": 
                [
                    {
                        \"advertiserId\"    : 462,
                        \"lastVisitTime\"   : 1597159444,
                        \"lstSrchNtvLocId\" : 379817478,
                        \"expireAt\"        : 1599751589
                    }
                ]
            }
        }"

printf -- "\n"
