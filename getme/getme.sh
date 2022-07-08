#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "USAGE:"
  echo ""
  echo "  ${0} PROGRAM [VERSION]"
  echo ""
  echo "EXAMPLES:"
  echo ""
  echo "  ${0} helmfile 0.145.0"
  echo "  ${0} helmfile latest"
  echo ""
  echo "SUPPORTED PROGRAMS:"
  echo ""
  echo "  helm"
  echo "  helmfile"
  echo "  git-credential-manager"
  echo "  k3d"
  exit
fi

readonly PROGRAM="${1}"
readonly ARG_VERSION="${2:-latest}"
readonly NORM_VERSION="${ARG_VERSION/#v}" # Normalize v1.2.3 to 1.2.3

# Ensure we only prefix numeric versions with v
if [[ "${NORM_VERSION::1}" =~ [[:digit:]] ]]; then
    readonly VERSION="v${NORM_VERSION}"
else
    readonly VERSION="${NORM_VERSION}"
fi

get_gh_release_url() {
    local -r OWNER="${1}"
    local -r REPO="${2}"
    local -r TAG="${3:-latest}"
    local -r REGEX="${4:-linux_amd64}"

    # Set RELEASE differently depending on if TAG is latest or not
    if [[ "${TAG}" != "latest" ]]; then
        RELEASE="tags/${TAG}"
    else
        RELEASE="latest"
    fi

    local -r RELEASE_JSON=$(
        curl --silent -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${OWNER}/${REPO}/releases/${RELEASE}"
    )

    jq -r "
        .assets[]
        |
        select(.name | test(\"${REGEX}\"))
        |
        .browser_download_url
    " <(echo "${RELEASE_JSON}")

}

###########################     Program selector     ###########################
if [[ "${PROGRAM}" == "helm" ]]; then
    readonly DOWNLOAD_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
    readonly PACKAGE_FORMAT="bash"
    readonly DOWNLOAD_FORMAT="PLAIN"
elif [[ "${PROGRAM}" == "helmfile" ]]; then
    readonly DOWNLOAD_URL=$(
        get_gh_release_url \
            "${PROGRAM}" "${PROGRAM}" \
            "${VERSION}"
    )
    readonly PACKAGE_FORMAT="bin"
elif [[ "${PROGRAM}" == "git-credential-manager" ]]; then
    readonly DOWNLOAD_URL=$(
        get_gh_release_url \
            "GitCredentialManager" "${PROGRAM}" \
            "${VERSION}" \
            '.*gcm-linux_amd64.*.deb'
    )
    readonly PACKAGE_FORMAT="deb"
elif [[ "${PROGRAM}" == "k3d" ]]; then
    readonly DOWNLOAD_URL=$(
        get_gh_release_url \
            "k3d-io" "${PROGRAM}" \
            "${VERSION}" \
            'k3d-linux-amd64'
    )
    readonly PACKAGE_FORMAT="bin"
    readonly DOWNLOAD_FORMAT="PLAIN"
else
    echo "❌ ERROR: program ${PROGRAM} not supported."
    exit 1
fi


##########################     Download & Install     ##########################
DOWNLOAD_DIR=$(mktemp -d)
FILENAME=$(basename "${DOWNLOAD_URL}")
echo "⏳ Downloading ${PROGRAM} …"
if [[ "${DOWNLOAD_FORMAT:-x}" == "PLAIN" ]]; then
    wget -qO "${DOWNLOAD_DIR}/${PROGRAM}" "${DOWNLOAD_URL}"
elif [[ "${FILENAME}" == *.tar.gz ]]; then
    wget -qO - "${DOWNLOAD_URL}" | tar -xzC "${DOWNLOAD_DIR}"
elif [[ "${FILENAME}" == *.deb ]]; then
    wget -qo "${DOWNLOAD_DIR}/${FILENAME}" "${DOWNLOAD_URL}"
else
    echo "ERROR: Could not download ${PROGRAM}  ¯\_(ツ)_/¯"
    echo -e "  DIR:\t\t${DOWNLOAD_DIR}"
    echo -e "  URL:\t\t${DOWNLOAD_URL}"
    echo -e "  FILENAME:\t${FILENAME}"
    echo -e "  DOWNLOAD_FORMAT:\t${DOWNLOAD_FORMAT:-None}"
    exit 1
fi
echo "✅ Download complete!"

echo "⌛ Installing ${PROGRAM} …"
if [[ "${PACKAGE_FORMAT}" == "bin" ]]; then
    sudo install "${DOWNLOAD_DIR}/${PROGRAM}" /usr/local/bin/
elif [[ "${PACKAGE_FORMAT}" == "deb" ]]; then
    sudo apt install "${DOWNLOAD_DIR}/${PROGRAM}.deb"
elif [[ "${PACKAGE_FORMAT}" == "bash" ]]; then
    if [[ "${PROGRAM}" == "helm" ]]; then
        if [[ "${ARG_VERSION}" != "latest" ]]; then
            readonly HELM_VER="--version ${VERSION}"
        else
            readonly HELM_VER=""
        fi
        bash "${DOWNLOAD_DIR}/${PROGRAM}" ${HELM_VER}
    fi
else
    echo "ERROR: Package format was ${PACKAGE_FORMAT}  ¯\_(ツ)_/¯"
    exit 1
fi
echo "😀 Installation complete!"

