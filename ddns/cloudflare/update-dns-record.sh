#!/usr/bin/env bash

# https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record

# Path
readonly ZONE_ID=''
readonly RECORD_ID=''

# Headers
readonly API_TOKEN=''

# Data values
readonly TTL='3600'
readonly TYPE='A'
readonly HOSTNAME=''
readonly CONTENT=''

curl -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
     -H "Authorization: Bearer ${API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data "{'type':${TYPE},'name':${HOSTNAME},'content':${CONTENT},'ttl':${TTL},'proxied':false}"
