#!/usr/bin/env bash


set -euo pipefail

if [ ! $# -eq 2 ]; then
  echo "USAGE:"
  echo ""
  echo "  ${0} PROGRAM VERSION"
  echo ""
  echo "EXAMPLE:"
  echo ""
  echo "  ${0} helmfile 0.145.0"
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
    DOWNLOAD_URL="https://github.com/helmfile/helmfile/releases/download/v${VERSION}/helmfile_${VERSION}_linux_amd64.tar.gz"
    FILETYPE="tar.gz"
else
    echo "❌ ERROR: program ${PROGRAM} not supported."
    exit 1
fi

##########################     Download & Install     ##########################
DOWNLOAD_DIR=$(mktemp -d)

echo "⏳ Downloading ${PROGRAM} …"
if [[ "${FILETYPE}" == "tar.gz" ]]; then
    wget -qO - "${DOWNLOAD_URL}" | tar -xzC "${DOWNLOAD_DIR}"
else
    echo "ERROR: Filetype was ${FILETYPE}  ¯\_(ツ)_/¯"
    exit 1
fi
echo "✅ Download complete! "

echo "⌛ Installing ${PROGRAM} …"
sudo install "${DOWNLOAD_DIR}/${PROGRAM}" /usr/local/bin
echo "😀 Installation complete!"
