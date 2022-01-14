#!/usr/bin/env python3.9
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

""" git get

This script makes it easier to clone a git repo from e.g. Github and put it in
a directory according to the repo owner in the URI.
"""

# TODO: Unit tests
# Test strings:
# - https://github.com/lindhe/dotfiles
# - http://gitlab.example.com/lindhe/dotfiles
# - https://github.com/lindhe/dotfiles.git
# - git@github.com:lindhe/dotfiles.git
# - https://foo@dev.azure.com/foo/bar/_git/baz


import argparse
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


__author__ = "Andreas Lindhé"
__license__ = "MIT"
__version__ = "2.2.2"
description = "Clones a Git repo into a specified path."


def main(
    dry_run: bool,
    git_location: str,
    git_repo: str,
    group_by: str,
    verbose: int
):
    """ Clone the git repo """
    if verbose > 1:
        print("\nmain( "
              f"{dry_run=}, "
              f"{git_location=}, "
              f"{git_repo=}, "
              f"{group_by=}, "
              f"{verbose=} "
              ")")
    target_path = get_path_from_uri(
        base_path=git_location,
        group_by=group_by,
        repo_uri=git_repo,
        verbose=verbose
    )
    if verbose:
        print(f"{target_path=}")
    exit_if_target_exists(target_path, verbose)
    if not dry_run:
        os.makedirs(target_path, exist_ok=True)
        os.system(f"git clone {git_repo} {target_path}")


def exit_if_target_exists(target_path: Path, verbose=0):
    """ Exit with error code if target_path already exists """
    if verbose > 1:
        print("\nexit_if_target_exists( "
              f"{target_path=}, "
              f"{verbose=} "
              ")")
    if not os.path.exists(target_path):
        if verbose > 1:
            print("There exists no file or directory at "
                  f"{target_path}, so it's safe to continue.")
        return
    if not os.path.isdir(target_path):
        print(f"{target_path} exists, but it's not a directory!",
              file=sys.stderr)
        sys.exit(1)
    if any(os.scandir(target_path)):
        print(f"{target_path} exists, but it's not empty!",
              file=sys.stderr)
        sys.exit(1)


def get_path_from_uri(
    base_path: str,
    group_by: str,
    repo_uri: str,
    verbose=0
) -> Path:
    """ Given a URI to a git repo, return the target path. """
    if verbose > 1:
        print(f"\nget_path_from_uri( "
              f"{base_path=}, "
              f"{group_by=}, "
              f"{repo_uri=} "
              ")"
              )
    group = ""
    if re.match('^git@', repo_uri):
        # git@github.com:lindhe/scripts.git
        uri_path = repo_uri.removesuffix(".git").split(':')[-1]
        owner, repo_name = uri_path.split("/")[-2:]
        if group_by:
            group = str(urlparse(repo_uri).hostname)
        if verbose > 1:
            print(f"Matched Git URI: {group=}, {owner=}, {repo_name=}")
    elif re.match('^https://', repo_uri):
        # https://github.com/lindhe/scripts.git
        owner, repo_name = repo_uri.removesuffix(".git").split("/")[-2:]
        if group_by:
            group = str(urlparse(repo_uri).hostname)
        if verbose > 1:
            print(f"Matched HTTPS URI: {group=}, {owner=}, {repo_name=}")
    else:
        print("Only the following protocols are supported in git-get:\n"
              "\tHTTPS (e.g. https://github.com/lindhe/scripts.git)\n"
              "\tSSH (e.g. git@github.com:lindhe/scripts.git)\n"
              "",
              file=sys.stderr)
        sys.exit(1)
    return Path(base_path, group, owner, repo_name)


if __name__ == '__main__':
    # Environment variables
    git_location = os.getenv('GLOBAL_GIT_LOCATION', os.path.expanduser('~') +
                             "/git")
    # Bootstrapping
    p = argparse.ArgumentParser(description=description)
    # Add cli arguments
    p.add_argument('git_repo', help="The git repo URI to clone.")
    p.add_argument('--dry-run', action='store_true',
                   help="Just print, never modify anything.")
    p.add_argument('--git-location',
                   default=git_location,
                   help="Overrides GLOBAL_GIT_LOCATION envvar as custom path"
                   " for storing git repos."
                   f" (default: {git_location})")
    p.add_argument('--group-by',
                   type=str,
                   choices=['hostname'],
                   help="Enables grouping into subdirectories "
                   "in the git location."
                   )
    p.add_argument('-v', '--verbose', action='count', default=0,
                   help="Verbosity level.")
    p.add_argument('-V', '--version', action='version', version=__version__)
    # Run:
    args = p.parse_args()
    if args.verbose > 1:
        print("\n__main__:")
        print(f"{args=}")
    try:
        main(
            dry_run=args.dry_run,
            git_location=args.git_location,
            git_repo=args.git_repo,
            verbose=args.verbose,
            group_by=args.group_by
        )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
