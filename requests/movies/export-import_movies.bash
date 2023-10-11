#!/bin/bash

# https://www.youtube.com/watch?v=5QQdNbvSGok


declare api_key host i id line ombi_requests_file
declare -A p

api_key=
host=

ombi_requests_file=$(mktemp)

curl -s -X 'GET' "https://${host}/api/v2/Requests/movie/processing/99999/0/title/title" -H 'accept: application/json' -H "ApiKey: ${api_key}" | jq -j '.collection[] | (.theMovieDbId, ":::", .requestedUser.email), "\n"' > "${ombi_requests_file}"


for i in $(curl -s -X 'GET' "https://${host}/api/v1/user?take=99999&skip=0" -H 'accept: application/json' -H "X-Api-Key: ${api_key}" | jq -j '.results[] | .id, ":::", .email, "\n"')
do
  p[${i%%:::*}]="${i##*:::}"
done

for id in "${!p[@]}"
do
  grep "${p[$id]}" "${ombi-requests_file}" | while read -r line
  do
    if ! curl -f -s -X 'POST' "https://${host}/api/v1/request" -H 'accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: ${api_key}" -d "\{\"mediaType\": \"movie\", \"mediaId\": ${line%%:::*}, \"userId\": ${id}\}"; then
      echo -e "FAIL: ${line%%:::*}"
    fi
  done
done
