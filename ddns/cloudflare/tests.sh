#!/usr/bin/env bash

## Misc test to run, not already covered by mypy and pylint

snap_version=$(grep -P "^version: " ./snap/snapcraft.yaml | cut -d ' ' -f 2)
program_version=$(grep -P "^__version__ = " ./update_dns_record.py | cut -d ' ' -f 3)

if [[ "${snap_version}" != "${program_version}" ]]; then
    >&2 echo "ERROR: snap version and program_version does not match"
    exit 1
fi
