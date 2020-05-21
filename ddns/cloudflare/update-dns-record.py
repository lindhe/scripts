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
import os
import sys
import requests
import pathlib

def main(content='',
    hostname='',
    ttl=3600,
    record_type='A',
    dryrun=False,
    verbose=False
    ):
  required_environment_variables = [
      'CF_DNS_API_TOKEN',
      'CF_DNS_ZONE_ID',
      'CF_DNS_RECORD_ID'
      ]
  assert_env_vars(required_environment_variables)

def assert_env_vars(envs: List):
  for e in envs:
    if not os.getenv(e):
      sys.exit(f'ERROR: Environment variable {e} is not defined.')

def update_record(
    content='',
    dryrun=False,
    hostname='',
    record_type='A',
    ttl=3600,
    verbose=False,
    ):
  # API endpoint
  api_endpoint = 'https://api.cloudflare.com/client/v4'
  api_path = pathlib.PurePath(
      'zones',
      os.getenv('CF_DNS_ZONE_ID'),
      'dns_records',
      os.getenv('CF_DNS_RECORD_ID')
      )
  full_url = f"{api_endpoint}/{str(api_path)}"
  # Headers
  api_token = os.getenv('CF_DNS_API_TOKEN')
  headers = {
      "Authorization": f"Bearer {API_TOKEN}",
      "Content-Type": "application/json"
      }
  if not dryrun:
    pass


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


