#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

from setuptools import setup, find_packages
setup(
    name="update_dns_record",
    version="1.1.0",
    packages=find_packages(),
    scripts=["update_dns_record.py"],

    # metadata to display on PyPI
    author="Andreas Lindhé",
    author_email="nope@example.com",
    url="http://example.com/",   # project home page, if any
    description="I cannot be arsed to repeat the description again. Please check the program help text, README or snap description.",
    keywords="cloudflare ddns dns",
)
