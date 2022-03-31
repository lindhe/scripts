#!/usr/bin/env bash


set -euo pipefail

if [ $# -eq 0 ]; then
  echo "USAGE:"
  echo ""
  echo "  ${0} PROGRAM VERSION"
  echo ""
  echo "EXAMPLE:"
  echo ""
  echo "  ${0} helmfile 0.144.0"
  echo ""
  echo "SUPPORTED PROGRAMS:"
  echo ""
  echo "helmfile"
  exit
fi

PROGRAM="${1}"
VERSION="${2}"

###########################     Program selector     ###########################
if [[ "${PROGRAM}" == "helmfile" ]]; then
    DOWNLOAD_URL="https://github.com/roboll/helmfile/releases/download/v${VERSION}/helmfile_linux_amd64"
else
    echo "ERROR: program "${PROGRAM}" not supported."
    exit 1
fi

##########################     Download & Install     ##########################
DOWNLOAD_DIR=$(mktemp -d)
echo wget -O "${DOWNLOAD_DIR}/${PROGRAM}" "${DOWNLOAD_URL}"
echo sudo install "${DOWNLOAD_DIR}/${PROGRAM}" /usr/local/bin
