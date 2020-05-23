# Update DNS record on Cloudflare

I'm moving from Loopia to Cloudflare, and need a new script that updates my DNS for me, since I don't have static IP.

## Installation

```shell
make
sudo make install
```

## Environment variables

To run the script, you must first set these environment variables:

```shell
CF_DNS_API_TOKEN
CF_DNS_ZONE_ID
CF_DNS_RECORD_ID
```

**Info about the API token:** https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys

**How to Get a Zone ID:** https://api.cloudflare.com/#getting-started-resource-ids

**Getting the Record ID:**
```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/${CF_DNS_ZONE_ID}/dns_records?type=A&name=test.lindhe.io" -H "Authorization: Bearer ${CF_DNS_API_TOKEN}" -H "Content-Type: application/json"
```


## Type checking and lint:

```shell
make test
```

## Dryrun

Note that these are just dummy values.

```shell
CF_DNS_API_TOKEN='YQSn-xWAQiiEh9qM58wZNnyQS7FUdoqGIUAbrh7T' CF_DNS_ZONE_ID='023e105f4ecef8ad9ca31a8372d0c353' CF_DNS_RECORD_ID='372e67954025e0ba6aaa6d586b9e0b59' ./update_dns_record.py --hostname example.com --content 127.0.0.1 --verbose --dryrun
```

