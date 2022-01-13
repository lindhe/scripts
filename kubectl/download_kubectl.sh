#!/usr/bin/env bash

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
# https://kubernetes.io/releases/

set -e

versions=(
    "1.20.14"
    "1.21.8"
    "1.22.5"
    "1.23.1"
)

for version in "${versions[@]}"; do
    echo "v${version} ..."
    curl -sLo "kubectl${version}" "https://dl.k8s.io/release/v${version}/bin/linux/amd64/kubectl"
    curl -sLo "kubectl${version}.sha256" "https://dl.k8s.io/v${version}/bin/linux/amd64/kubectl.sha256"
    echo "$(<kubectl"${version}".sha256) kubectl${version}" | sha256sum --check
done

# Install
read -p "Do you want to install all the downloaded Kubectl versions? (y/N)" -n 1 -r
echo -e "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit
fi

INSTALL_DIR=/usr/local/bin/
sudo mkdir -p ${INSTALL_DIR}
for version in "${versions[@]}"; do
    echo "Installing kubectl ${version} ..."
    sudo install "./kubectl${version}" "${INSTALL_DIR}"
done
