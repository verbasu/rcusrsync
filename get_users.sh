#!/bin/bash

# Domain of RC server
DOM=$1

CODE=$2

CACHE="./.rcauthcache"

V1="https://$DOM/api/v1"

function get_auth_token() {
	curl -k -s --request POST --url "$V1/login" \
		--header 'Accept: application/json' \
		--header 'Content-Type: application/json' \
		--header "x-2fa-code: $CODE" \
		--header 'x-2fa-method: totp' \
		--data '{
				"user": "username",
				"password": "password"
		}' > $CACHE
}

function get_all_users() {
	TOKEN=`cat $CACHE |jq '.data.authToken'|awk -F'"' '{print $2}'`
	ID=`cat $CACHE |jq '.data.userId'|awk -F'"' '{print $2}'`
	PAGE=150
	OFFSET=0
	echo '' > users.json
	while true; do
			URL=$V1'/users.list?offset='$OFFSET
			echo $OFFSET
			curl -k -s --request GET --url $URL \
				--header "X-Auth-Token: $TOKEN" \
				--header 'Accept: application/json' \
				--header 'Content-Type: application/json' \
				--header "X-User-Id: $ID" | jq -c '.users[] | [.name?,.username,.emails[]?.address]' >> users.json || break
			OFFSET=$(($OFFSET+$PAGE))
	done

}

function format_users() {
		jq -c '.users[] | [.name?,.username,.emails[].address?]'
}

#get_auth_token
get_all_users
