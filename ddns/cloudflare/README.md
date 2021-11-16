# Update DNS record on Cloudflare

I'm moving from Loopia to Cloudflare, and need a new script that updates my DNS for me, since I don't have static IP.

## Prerequisites

* python3.9
* python3.9-dev
* python3-pip
* pipenv

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
```

**Info about the API token:** https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys

**How to Get a Zone ID:** https://api.cloudflare.com/#getting-started-resource-ids

## Type checking and lint:

```shell
make test
```

## Dryrun

Note that these are just dummy values.

```shell
CF_DNS_API_TOKEN='YQSn-xWAQiiEh9qM58wZNnyQS7FUdoqGIUAbrh7T' CF_DNS_ZONE_ID='023e105f4ecef8ad9ca31a8372d0c353' ./update_dns_record.py --hostname example.com --content 127.0.0.1 --verbose --dryrun
```

## Security notices

This script uses https://ipv4.icanhazip.com for IP lookups.
If that side is compromised, a malicious actor can cause your cronjob to point your DNS record to something you didn't intend.
