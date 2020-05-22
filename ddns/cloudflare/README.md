# Update DNS record on Cloudflare

I'm moving from Loopia to Cloudflare, and need a new script that updates my DNS for me, since I don't have static IP.

## Installation

```shell
pipenv install
pipenv run ./update-dns-record.py -h
```

## Type checking and lint:

```shell
pipenv run mypy ./update-dns-record.py
pipenv run pylint ./update-dns-record.py
```

## Dryrun

```shell
CF_DNS_API_TOKEN='YQSn-xWAQiiEh9qM58wZNnyQS7FUdoqGIUAbrh7T' CF_DNS_ZONE_ID='023e105f4ecef8ad9ca31a8372d0c353' CF_DNS_RECORD_ID='372e67954025e0ba6aaa6d586b9e0b59' ./update_dns_record.py --hostname example.com --content 127.0.0.1 --verbose --dryrun
```
