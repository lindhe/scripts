#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

""" Update Cloudflare DNS record
This script helps you to update a DNS recrod that lives on Cloudflare.

Before running, make sure you have set the following environment variables:
CF_DNS_API_TOKEN
CF_DNS_ZONE_ID
CF_DNS_RECORD_ID

Documentation about the API can be found here:
https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record

"""

from typing import List
import argparse
import json
import os
import pathlib
import requests
import sys


def main(content='',
    hostname='',
    ttl=3600,
    record_type='A',
    dryrun=False,
    verbose=False
    ):
  if verbose:
    print(f"dryrun = {dryrun}")
  required_environment_variables = [
      'CF_DNS_API_TOKEN',
      'CF_DNS_ZONE_ID',
      'CF_DNS_RECORD_ID'
      ]
  assert_env_vars(required_environment_variables)
  # Compare IP to avoid updating unnecessarily
  my_ip = current_public_ip()
  record_ip = get_ip_from_record(dryrun=dryrun, verbose=verbose)
  # Only update record if the IPxs differ
  if my_ip != record_ip:
    if verbose:
      print('Current IP differs from DNS record.')
    update_record(
        content=content,
        dryrun=dryrun,
        hostname=hostname,
        record_type=record_type,
        ttl=ttl,
        verbose=verbose
        )

def assert_env_vars(envs: List):
    unset_variables = []
    for e in envs:
        if not os.getenv(e):
            unset_variables.append(e)
    if unset_variables:
        print('ERROR: The following environment variables were not set:\n',
              unset_variables, file=sys.stderr)
        sys.exit(1)


def send_request(
    method: str,
    data={},
    dryrun=False,
    verbose=False,
    ) -> requests.Response:
  assert method in ['get', 'put', 'post'], f"Incorrect method {method} for send_request()"
  url = make_api_url(verbose=verbose)
  headers = make_headers(verbose=verbose)
  if verbose and data:
    print('Data:\n' + json.dumps(data, indent=4) + '\n')
  if not dryrun:
    if verbose:
      print("Sending request...")
    if method == 'get':
      res = requests.get(url, headers=headers)
    if method == 'put':
      res = requests.put(url, headers=headers, data=data)
    if res.ok:
      if verbose:
        print('Success!')
        print('# Repsonse:\n' + res.json())
    else:
      rq = res.request
      print('\n')
      print('# Request:\n'
          + 'Method: ' + str(rq.method) + '\n'
          + 'URL: ' + str(rq.url) + '\n'
          + 'Headers:\n' + str(rq.headers) + '\n'
          , file=sys.stderr)
      print('\n')
      print('Repsonse:\n' + res.json(), file=sys.stderr)
      sys.exit(f"ERROR: got an error when sending request.")
  return res

def update_record(
    content='',
    dryrun=False,
    hostname='',
    record_type='A',
    ttl=3600,
    verbose=False,
    ):
  # Data
  data = {
      'type': record_type,
      'name': hostname,
      'content': content,
      'ttl': ttl,
      }
  print("Sending request to update record...")
  send_request(
      'put',
      data = data,
      dryrun = dryrun,
      verbose = verbose
      )

def get_ip_from_record(dryrun=False, verbose=False) -> str:
    res = send_request(
        'get',
        dryrun = dryrun,
        verbose = verbose
        )
    # Setting ip to return something during dryrun
    ip = '127.0.0.1'
    if not dryrun:
        ip = res.json()['result']['content']
    return ip


def make_headers(verbose=False) -> dict:
    headers = {
        "Authorization": f"Bearer {os.getenv('CF_DNS_API_TOKEN')}",
        "Content-Type": "application/json"
        }
    if verbose:
        print('\n')
        print('Headers:\n' + json.dumps(headers, indent=4) + '\n')
    return headers


def make_api_url(verbose=False) -> str:
    # API endpoint
    api_endpoint = 'https://api.cloudflare.com/client/v4'
    api_path = pathlib.PurePath(
        'zones',
        str(os.getenv('CF_DNS_ZONE_ID')),
        'dns_records',
        str(os.getenv('CF_DNS_RECORD_ID'))
        )
    url = f"{api_endpoint}/{str(api_path)}"
    if verbose:
        print('\n')
        print('URL:\n' + url + '\n')
    return url

# Get current public IP
def current_public_ip() -> str:
  return requests.get('https://ipv4.icanhazip.com').text.strip()


if __name__ == '__main__':
  # Bootstrapping
  p = argparse.ArgumentParser(description="Updates a DNS record on Cloudflare")
  # Add cli arguments
  p.add_argument('--content', help="content of the hostname", required=True)
  p.add_argument('--dryrun', help="run without sending any requests", action="store_true")
  p.add_argument('--hostname', help="hostname to update", required=True)
  p.add_argument('--ttl', help="ttl in seconds for the DNS record (default: 3600)", default=3600)
  p.add_argument('--type', help="record type (default: A)", choices=['A', 'AAAA', 'CNAME'], default='A')
  p.add_argument('--verbose', help="print more", action="store_true")
  # Run:
  args = p.parse_args()
  try:
    main(
        content=args.content,
        dryrun=args.dryrun,
        hostname=args.hostname,
        ttl=args.ttl,
        record_type=args.ttl,
        verbose=args.verbose
        )
  except KeyboardInterrupt:
    sys.exit("\nInterrupted by ^C\n")


