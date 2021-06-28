#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

""" git get

This script makes it easier to clone a git repo from e.g. Github and put it in
a directory according to the repo owner in the URL.
"""


import sys
import argparse


__author__ = "Andreas Lindhé"
__license__ = "MIT"
__version__ = "0.1.0"
description = "Takes a URI to a Git repo and clones it into a specified path."


def main(dry_run):
    """ Clone the git repo """
    print(f"{dry_run=}")


if __name__ == '__main__':
    # Bootstrapping
    p = argparse.ArgumentParser(description=description)
    # Add cli arguments
    p.add_argument('--dry-run', action='store_true',
                   help="Just print, never modify anything.")
    p.add_argument('-V', '--version', action='version', version=__version__)
    # Run:
    args = p.parse_args()
    try:
        main(
            dry_run=args.dry_run
        )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
