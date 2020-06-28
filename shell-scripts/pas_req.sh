#/bin/bash

. $(dirname "$0")/functions/base.sh


# ##############################################################################################################

user_id="9d7f20be-088a-4775-b408-d47180b2ecd9"

user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 Chrome/83.0.4103.97 Safari/537.36"

user_segments='{"typeOne":["1","4","7"],"typeTwo":[4,10]}'

page_url="https://www.mapquest.com/routeplanner"

pas_url="https://www.clicktripz.com/x/pas"

site_name="mapquest"

placement_id="2819-0"

# ##############################################################################################################

pas_proto="$(echo ${pas_url} | grep :// | sed -e's,^\(.*://\).*,\1,g')"
pas_path="$(echo ${pas_url/$pas_proto/})"
pas_host="$(echo ${pas_path} | cut -d/ -f1)"

pas_params=$(join_by "&"  \
   "ctzpid=$(uuidgen)" \
   "alias=${site_name}" \
   "siteId=${site_name}" \
   "placementId=${placement_id}" \
   "audiences=$(url_encode $user_segments)" \
   "ref=$(url_encode $page_url)" \
   "optMaxChecked=2" \
   "optMaxAdvertisers=7" \
   "optRotationStrategy=1" \
   "optPopUnder=1" \
   "optLocalization=en" \
   "tabbedMode=1" \
   "userForcedTabbedMode=1" \
   "callback=jsonp_func" \
   "obj=exit_unit" \
   )

curl  "${pas_url}?${pas_params}" \
  -H "authority:${pas_host}" \
  -H "user-agent: ${user_agent}" \
  -H 'accept: */*' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-mode: no-cors' \
  -H 'sec-fetch-dest: script' \
  -H "referer: ${page_url}" \
  -H 'accept-language: en-US,en;q=0.9,ru;q=0.8' \
  -H "cookie: _ctuid=${user_id};" \
  --compressed

