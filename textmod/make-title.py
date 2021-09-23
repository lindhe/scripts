#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

""" Make Title

Sometimes you want to make a comment in a file and looks more like a title than
the other comments.
This script helps you do that.

Foo --> ############################     Foo     ############################
"""

import argparse
import sys

__author__ = "Andreas Lindhé"
__license__ = "MIT"
__version__ = "0.1.0"
description = """Sometimes you want to make a comment in a file and looks more
like a title than the other comments. This script helps you do that."""


def main(text: str, width: int, garment: str):
    """ Makes the text into a title string. """
    print(make_title(body=text, garment=garment, width=width))


def make_title(body: str, garment: str, width: int, margin=2) -> str:
    """ Takes a naked string and dresses it up with garments. """
    body = body.strip()
    garment_width = (width - len(body) - 2*margin)//2
    side = garment*garment_width
    padding = ' '*margin
    return side + padding + body + padding + side


if __name__ == '__main__':
    # Default values
    DEFAULT_LINE_WIDTH = 80
    DEFAULT_GARMENT = '#'

    # Bootstrapping
    p = argparse.ArgumentParser(description=description)

    # Flags
    p.add_argument('-g', '--garment', default=DEFAULT_GARMENT,
                   help="Garment to dress the string in "
                   + f"(default: {DEFAULT_GARMENT})")
    p.add_argument('-w', '--line-width', type=int, default=DEFAULT_LINE_WIDTH,
                   help=f"Line width (default: {DEFAULT_LINE_WIDTH})")
    p.add_argument('-V', '--version', action='version', version=__version__)

    # Positional arguments
    # I don't love that using FileType here will make parse_args open the file.
    p.add_argument('input', nargs='?', type=argparse.FileType('r'),
                   default=sys.stdin,
                   help="File to read (default: stdin)")

    # Parse the args
    args = p.parse_args()
    first_line = args.input.readlines()[0]
    args.input.close()

    try:
        main(
            text=first_line,
            width=args.line_width,
            garment=args.garment
        )
    except KeyboardInterrupt:
        sys.exit("\nInterrupted by ^C\n")
