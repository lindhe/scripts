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

__version__ = '1.4.1'
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
        timeout=10,
        ttl=3600,
        record_type='A',
        dryrun=False,
        verbose=None
        ):
    """ Update a DNS record to match the current IP address. """
    if verbose > 1:
        print(f"Version: {__version__}")
        print(f"dryrun = {dryrun}")
    required_environment_variables = [
        'CF_DNS_API_TOKEN',
        'CF_DNS_ZONE_ID',
        ]
    assert_env_vars(required_environment_variables)
    dns_record = get_record_json(hostname, record_type=record_type,
                                 timeout=timeout,
                                 dryrun=dryrun, verbose=verbose)
    record_content: str = dns_record['result']['content']
    # Compare IP to avoid updating unnecessarily
    my_ip: str = ip_address or current_public_ip(timeout=timeout,
                                                 verbose=verbose)
    # Only update record if the IPxs differ
    if my_ip != record_content:
        if verbose > 0:
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
        if verbose > 0:
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
        timeout=10,
        dryrun=False,
        verbose=None,
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
        if verbose > 2:
            print("Sending {} request...".format(method.upper()))
        try:
            if method == 'get':
                res = requests.get(url, headers=headers, params=parameters,
                                   timeout=timeout)
            if method == 'put':
                res = requests.put(url, headers=headers, json=json_data,
                                   timeout=timeout)
        except requests.Timeout as error:
            print("ERROR: Timeout was raised in send_request()",
                  file=sys.stderr)
            print(error, file=sys.stderr)
            sys.exit(1)
        except requests.ConnectionError as error:
            print("A Connection exception was raised in send_request().",
                  file=sys.stderr)
            print(error, file=sys.stderr)
            sys.exit(1)
        if res.ok:
            if verbose > 2:
                print('Success!')
                print('# Repsonse:')
                print(res.json())
        else:
            request = res.request
            print('\n', file=sys.stderr)
            print('# Request:\n'
                  + 'Method: ' + str(request.method) + '\n'
                  + 'URL: ' + str(request.url) + '\n'
                  + 'Headers:\n' + str(censor_headers(dict(request.headers)))
                  + '\n', file=sys.stderr)
            print('\n', file=sys.stderr)
            print('Repsonse:', file=sys.stderr)
            print(res.text, file=sys.stderr)
            sys.exit("ERROR: got an error when sending request.")
    return res


def update_record(
        content='',
        dryrun=False,
        hostname='',
        record_type='A',
        timeout=10,
        ttl=3600,
        verbose=None,
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
    if verbose > 1:
        print("Sending request to update record...")
    send_request(
        'put',
        hostname,
        json_data=json_data,
        timeout=timeout,
        dryrun=dryrun,
        verbose=verbose
        )
    print(f"Successfully updated DNS record of {hostname}" +
          f" to point to {content}")


def get_record_json(hostname: str, record_type='A', timeout=10,
                    dryrun=False, verbose=None) -> dict:
    """ Gets a DNS record. """
    if verbose > 1:
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
            timeout=timeout,
            dryrun=dryrun,
            verbose=verbose
        ).json()
    return record_json


def make_headers(verbose=None) -> dict:
    """ Return a dict of properly formatted headers with token auth. """
    headers = {
        "Authorization": f"Bearer {os.getenv('CF_DNS_API_TOKEN')}",
        "Content-Type": "application/json"
        }
    if verbose > 2:
        # Redacting token as to not print it in the logs
        censored_headers = censor_headers(headers)
        print('Headers:\n' + json.dumps(censored_headers, indent=4) + '\n')
    return headers


def censor_headers(headers: dict, field='Authorization') -> dict:
    """ Returns a copy of headers with field being censored. """
    censored_headers = dict(headers)
    censored_headers[field] = '***'
    return censored_headers


def make_api_url(hostname: str, record_type='A',
                 dryrun=False, verbose=None) -> str:
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
    if verbose > 2:
        print('URL: ' + url)
    return url


def get_record_id(hostname: str, record_type='A', timeout=10,
                  dryrun=False, verbose=None) -> str:
    """ Return the Record ID for a hostname in the configured zone. """
    if verbose > 2:
        print(f"Getting Record ID for {hostname}")
    if dryrun:
        record_id = '372e67954025e0ba6aaa6d586b9e0b59'
        if verbose > 1:
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
                           timeout=timeout,
                           dryrun=dryrun,
                           verbose=verbose,
                           )
        records = res.json()['result']
        if len(records) > 1:
            print("WARNING: more than one record found. Assuming index 0.",
                  file=sys.stderr)
            print(records, file=sys.stderr)
        record_id = records[0]['id']
        if verbose > 1:
            print(f"Record ID for {hostname} is {record_id}")
    return record_id


def get_zone_id(dryrun=False, verbose=None) -> str:
    """ Return the Zone ID for the configured zone. """
    dummy_id = '023e105f4ecef8ad9ca31a8372d0c353'
    if verbose > 2:
        print("Getting Zone ID...")
        if dryrun:
            print(f"Picking dummy value for Zone ID: {dummy_id}")
    return dummy_id if dryrun else str(os.getenv('CF_DNS_ZONE_ID'))


def current_public_ip(timeout=10, verbose=None) -> str:
    """ Get current public IP. """
    if verbose > 1:
        print("Looking up current IP address for this host...")
    try:
        res = requests.get('https://ipv4.icanhazip.com', timeout=timeout)
    except requests.Timeout as error:
        print("ERROR: Timeout was raised in current_public_ip()",
              file=sys.stderr)
        print(error, file=sys.stderr)
        sys.exit(1)
    except requests.ConnectionError as error:
        print("ERROR: ConnectionError was raised in current_public_ip()",
              file=sys.stderr)
        print(error, file=sys.stderr)
        sys.exit(1)
    ip_address: str = res.text.strip()
    if verbose > 1:
        print(ip_address)
    return ip_address


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
        '--timeout',
        help="Requests Read and Connect timeout in seconds (default: 10)",
        default=10)
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
    p.add_argument('-v', '--verbose', help="verbosity level [-v|-vv|-vvv]",
                   action="count", default=0)
    p.add_argument('--version', action='version', version=__version__)
    # Run:
    args = p.parse_args()
    try:
        main(
            dryrun=args.dryrun,
            hostname=args.hostname,
            ip_address=args.ip_address,
            timeout=args.timeout,
            ttl=args.ttl,
            record_type=args.type,
            verbose=args.verbose
            )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
