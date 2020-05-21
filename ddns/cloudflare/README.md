# Update DNS record on Cloudflare

I'm moving from Loopia to Cloudflare, and need a new script that updates my DNS for me, since I don't have static IP.

## Installation

```shell
pipenv install
pipenv run ./update-dns-record.py -h
```

## Type checking:

```shell
pipenv run mypy ./update-dns-record.py
```
