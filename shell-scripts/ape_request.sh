#!/bin/bash

endpoint="https://prod-ds-machine-learning.cubaneddie.k8s.clicktripz.io/v1/audience_pricing"
endpoint="http://localhost:8888/v1/audience_pricing"

curl --request POST ${endpoint} \
        --data-raw "{
                \"currentTimestamp\": 1597159444,
                \"audiences\": {\"typeOne\": [\"21\"]},
                \"alias\" : \"mapquest\",
                \"deviceID\": 101,
                \"deviceName\": \"Desktop\",
                \"browserID\": 1,
                \"browserName\": \"Chrome\",
                \"ctzUserID\": \"d83dc1ae-0126-47ac-9231-11aed27c6ba7\",
                \"profile\": {\"advertisers\": [
                                {
                                \"advertiserId\": 462,
                                \"lastVisitTime\": 1597159444,
                                \"lstSrchNtvLocId\": 379817478,
                                \"expireAt\": 1599751589
                                }
                        ]
                }
        }"

