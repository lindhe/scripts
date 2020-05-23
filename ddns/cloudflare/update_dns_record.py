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

Documentation about the API can be found here:
https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record

"""

__version__ = '1.0.0'
__author__ = 'Andreas Lindhé'

# Standard imports
from typing import List
import argparse
import json
import os
import pathlib
import sys

# External imports
import requests

API_ENDPOINT = 'https://api.cloudflare.com/client/v4'


def main(
        hostname='',
        ip_address='',
        ttl=3600,
        record_type='A',
        dryrun=False,
        verbose=False
        ):
    """ Update a DNS record to match the current IP address. """
    if verbose:
        print(f"dryrun = {dryrun}")
    required_environment_variables = [
        'CF_DNS_API_TOKEN',
        'CF_DNS_ZONE_ID',
        ]
    assert_env_vars(required_environment_variables)
    dns_record = get_record_json(hostname, record_type=record_type,
                                 dryrun=dryrun, verbose=verbose)
    record_content: str = dns_record['result']['content']
    # Compare IP to avoid updating unnecessarily
    my_ip: str = ip_address or current_public_ip(verbose=verbose)
    # Only update record if the IPxs differ
    if my_ip != record_content:
        if verbose:
            print('Current IP differs from DNS record.')
        update_record(
            content=my_ip,
            dryrun=dryrun,
            hostname=hostname,
            record_type=record_type,
            ttl=ttl,
            verbose=verbose
            )
    else:
        print('DNS record unchanged.')


def assert_env_vars(envs: List):
    """ Checks a list of environment variables to make sure they are set. """
    unset_variables = []
    for variable in envs:
        if not os.getenv(variable):
            unset_variables.append(variable)
    if unset_variables:
        print('ERROR: The following environment variables were not set:\n',
              unset_variables, file=sys.stderr)
        sys.exit(1)


def send_request(
        method: str,
        hostname: str,
        api_url='',
        json_data=None,
        record_type='A',
        parameters=None,
        dryrun=False,
        verbose=False,
        ) -> requests.Response:
    """ Sends an API request to Cloudflare. """
    assert method in ['get', 'put',
                      'post'], f"Incorrect method {method} for send_request()"
    url: str = api_url or make_api_url(hostname, record_type=record_type,
                                       dryrun=dryrun, verbose=verbose)
    headers: dict = make_headers(verbose=verbose)
    if verbose and json_data:
        print('Data:\n' + json.dumps(json_data, indent=4) + '\n')
    # We must supply a return value during dryrun.
    res = requests.Response()
    if not dryrun:
        if verbose:
            print("Sending {} request...".format(method.upper()))
        if method == 'get':
            res = requests.get(url, headers=headers, params=parameters)
        if method == 'put':
            res = requests.put(url, headers=headers, json=json_data)
        if res.ok:
            if verbose:
                print('Success!')
                print('# Repsonse:')
                print(res.json())
        else:
            request = res.request
            print('\n', file=sys.stderr)
            print('# Request:\n'
                  + 'Method: ' + str(request.method) + '\n'
                  + 'URL: ' + str(request.url) + '\n'
                  + 'Headers:\n' + str(request.headers)
                  + '\n', file=sys.stderr)
            print('\n', file=sys.stderr)
            print('Repsonse:', file=sys.stderr)
            print(res.json(), file=sys.stderr)
            sys.exit("ERROR: got an error when sending request.")
    return res


def update_record(
        content='',
        dryrun=False,
        hostname='',
        record_type='A',
        ttl=3600,
        verbose=False,
        ):
    """ Update a DNS record to hold a new value. """
    # Data
    json_data = {
        'type': record_type,
        'name': hostname,
        'content': content,
        'ttl': ttl,
        'proxied': False,
        }
    if verbose:
        print("Sending request to update record...")
    send_request(
        'put',
        hostname,
        json_data=json_data,
        dryrun=dryrun,
        verbose=verbose
        )
    print(f"Successfully updated DNS record of {hostname}" +
          f" to point to {content}")


def get_record_json(hostname: str, record_type='A',
                    dryrun=False, verbose=False) -> dict:
    """ Gets a DNS record. """
    if verbose:
        print("Getting DNS record...")
    # Dummy record to return on dryrun
    record_json = {  # {{{
        'result': {
            'id': '372e67954025e0ba6aaa6d586b9e0b59',
            'zone_id': '023e105f4ecef8ad9ca31a8372d0c353',
            'zone_name': 'example.com',
            'name': hostname,
            'type': 'A',
            'content': '127.0.0.1',
            'proxiable': True,
            'proxied': False,
            'ttl': 3600,
            'locked': False,
            'meta': {
                'auto_added': False,
                'managed_by_apps': False,
                'managed_by_argo_tunnel': False,
                'source': 'primary'
            },
            'created_on': '2020-05-23T10:36:08.607086Z',
            'modified_on': '2020-05-23T10:36:08.607086Z'
        },
        'success': True,
        'errors': [],
        'messages': []
    }
# }}}
    if not dryrun:
        record_json = send_request(
            'get',
            hostname,
            record_type=record_type,
            dryrun=dryrun,
            verbose=verbose
        ).json()
    return record_json


def make_headers(verbose=False) -> dict:
    """ Return a dict of properly formatted headers with token auth. """
    headers = {
        "Authorization": f"Bearer {os.getenv('CF_DNS_API_TOKEN')}",
        "Content-Type": "application/json"
        }
    if verbose:
        # Redacting token as to not print it in the logs
        censored_headers = dict(headers)
        censored_headers['Authorization'] = "Bearer ***"
        print('Headers:\n' + json.dumps(censored_headers, indent=4) + '\n')
    return headers


def make_api_url(hostname: str, record_type='A',
                 dryrun=False, verbose=False) -> str:
    """ Return the API URL for the configured record. """
    # API endpoint
    api_path = pathlib.PurePath(
        'zones',
        get_zone_id(dryrun=dryrun, verbose=verbose),
        'dns_records',
        get_record_id(hostname, record_type=record_type,
                      dryrun=dryrun, verbose=verbose)
        )
    url = f"{API_ENDPOINT}/{str(api_path)}"
    if verbose:
        print('URL: ' + url)
    return url


def get_record_id(hostname: str, record_type='A',
                  dryrun=False, verbose=False) -> str:
    """ Return the Record ID for a hostname in the configured zone. """
    if verbose:
        print(f"Getting Record ID for {hostname}")
    if dryrun:
        record_id = '372e67954025e0ba6aaa6d586b9e0b59'
        if verbose:
            print(f"Picking dummy value for Record ID: {record_id}")
    if not dryrun:
        zone_id: str = get_zone_id(dryrun=dryrun, verbose=verbose)
        url = f"{API_ENDPOINT}/zones/{zone_id}/dns_records"
        query = {'type': record_type, 'name': hostname}
        res = send_request('get',
                           hostname,
                           api_url=url,
                           record_type=record_type,
                           parameters=query,
                           dryrun=dryrun,
                           verbose=verbose,
                           )
        # TODO: we get a list of records. Would be nice to know that there's
        # only one item in the list...
        record_id = res.json()['result'][0]['id']
        if verbose:
            print(f"Record ID for {hostname} is {record_id}")
    return record_id


def get_zone_id(dryrun=False, verbose=False) -> str:
    """ Return the Zone ID for the configured zone. """
    dummy_id = '023e105f4ecef8ad9ca31a8372d0c353'
    if verbose:
        print("Getting Zone ID...")
        if dryrun:
            print(f"Picking dummy value for Zone ID: {dummy_id}")
    return dummy_id if dryrun else str(os.getenv('CF_DNS_ZONE_ID'))


def current_public_ip(verbose=False) -> str:
    """ Get current public IP. """
    if verbose:
        print("Looking up current IP address for this host...")
    return requests.get('https://ipv4.icanhazip.com').text.strip()


if __name__ == '__main__':
    # Bootstrapping
    p = argparse.ArgumentParser(
        description="Updates a DNS record on Cloudflare")
    # Add cli arguments
    p.add_argument(
        '--dryrun',
        help="run without sending any requests",
        action="store_true")
    p.add_argument('--hostname', help="hostname to update", required=True)
    p.add_argument(
        '--ip-address',
        help="instead of looking up this host's IP, use this one")
    p.add_argument(
        '--ttl',
        help="ttl in seconds for the DNS record (default: 3600)",
        default=3600)
    p.add_argument(
        '--type',
        help="record type (default: A)",
        choices=[
            'A',
            'AAAA',
            'CNAME'],
        default='A')
    p.add_argument('--verbose', help="print more", action="store_true")
    p.add_argument('--version', action='version', version=__version__)
    # Run:
    args = p.parse_args()
    try:
        main(
            dryrun=args.dryrun,
            hostname=args.hostname,
            ip_address=args.ip_address,
            ttl=args.ttl,
            record_type=args.type,
            verbose=args.verbose
            )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
