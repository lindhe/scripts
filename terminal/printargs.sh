#!/usr/bin/env bash
# A script to print the given arguments, to help me debug things.

set -euo pipefail

echo -e "${0} was called with the following arguments:\n"

i=1
for arg in "${@:i}"; do
  echo "\${${i}} was:" ">${arg}<"
  i=$((i+1))
done
