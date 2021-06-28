#!/usr/bin/env python3
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


import argparse
import os
import sys
from pathlib import Path


__author__ = "Andreas Lindhé"
__license__ = "MIT"
__version__ = "0.1.0"
description = "Takes a URI to a Git repo and clones it into a specified path."


def main(git_location: str, git_repo: str, dry_run: bool):
    """ Clone the git repo """
    print(f"{git_location=}")
    print(f"{git_repo=}")
    print(f"{dry_run=}")
    target_path = get_path_from_uri(git_repo)
    exit_if_target_exists(target_path)
    create_path(target_path, dry_run=dry_run)
    git_clone(repo_uri=git_repo, target_path=target_path, dry_run=dry_run)


def exit_if_target_exists(target_path: Path):
    """ Exit with error code if target_path already exists """
    pass


def get_path_from_uri(repo_uri: str):
    """ Given a URI to a git repo, return the target path. """
    return "/tmp/todo"


def create_path(path: str, dry_run=False):
    """ Safely create path. Is idempotent. """
    # TODO: mkdir -p $path
    pass


def git_clone(repo_uri: str, target_path: Path, dry_run=False):
    """ git clone a repo to a specific target location. """
    # TODO: git clone "${repo_uri}" "${target_path}"
    pass


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
    p.add_argument('-V', '--version', action='version', version=__version__)
    # Run:
    args = p.parse_args()
    try:
        main(
            git_location=args.git_location,
            git_repo=args.git_repo,
            dry_run=args.dry_run
        )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
