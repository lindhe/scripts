#!/usr/bin/env bash
# vim: ts=4 sw=4:

set -euo pipefail

stderr() {
    echo "$@" >&2
}

fail() {
    stderr "${1}"
    stderr ""
    stderr "Exiting …"
    exit "${2:-1}"
}

missing_dependencies=false
readonly dependencies=(
  curl
  jq
  wget
)
for dep in "${dependencies[@]}"; do
  if ! command -v "${dep}" &> /dev/null; then
    stderr "❌ ERROR: Missing dependency ${dep}"
    missing_dependencies=true
  fi
done

if ${missing_dependencies}; then
  fail 'Please install the missing dependencies!'
fi
if [[ -n ${VERBOSE+x} ]]; then
    stderr "GetMe"
    stderr "  … some programs!"
    stderr ""
fi

if [[ ${VERBOSE:-0} -gt 1 ]]; then
    set -x
fi

if [ $# -lt 1 ]; then
  stderr "USAGE:"
  stderr ""
  stderr "  ${0} PROGRAM [VERSION]"
  stderr ""
  stderr "EXAMPLES:"
  stderr ""
  stderr "  ${0} helmfile 0.145.0"
  stderr "  ${0} helmfile latest"
  stderr ""
  stderr "SUPPORTED PROGRAMS:"
  stderr ""
  stderr "  git-credential-manager"
  stderr "  hadolint"
  stderr "  helm"
  stderr "  helmfile"
  stderr "  k3d"
  stderr "  kubectl"
  stderr "  nvm"
  stderr "  sops"
  stderr "  yq"
  exit
fi

declare -r PROGRAM="${1}"
declare -r ARG_VERSION="${2:-latest}"
declare -r NORM_VERSION="${ARG_VERSION/#v}" # Normalize v1.2.3 to 1.2.3

# Ensure we only prefix numeric versions with v
if [[ "${NORM_VERSION::1}" =~ [[:digit:]] ]]; then
    declare -r VERSION="v${NORM_VERSION}"
else
    declare -r VERSION="${NORM_VERSION}"
fi

if [[ -n ${VERBOSE+x} ]]; then
    stderr ""
    stderr "Version"
    stderr "  ARG_VERSION:  ${ARG_VERSION:-None}"
    stderr "  NORM_VERSION: ${NORM_VERSION:-None}"
    stderr "  VERSION:      ${VERSION:-None}"
    stderr ""
fi

get_gh_release_url() {
    declare -r OWNER="${1}"
    declare -r REPO="${2}"
    declare -r TAG="${3:-latest}"
    declare -r REGEX="${4:-linux_amd64}"

    if [[ -n ${VERBOSE+x} ]]; then
        stderr ""
        stderr "get_gh_release_url()"
        stderr "  OWNER: ${OWNER:-None}"
        stderr "  REPO:  ${REPO:-None}"
        stderr "  TAG:   ${TAG:-None}"
        stderr "  REGEX: ${REGEX:-None}"
        stderr ""
    fi

    # Set RELEASE differently depending on if TAG is latest or not
    if [[ "${TAG}" != "latest" ]]; then
        RELEASE="tags/${TAG}"
    else
        RELEASE="latest"
    fi

    if [[ -n ${VERBOSE+x} ]]; then
        stderr ""
        stderr "RELEASE: ${RELEASE:?}"
        stderr ""
    fi

    declare -r RELEASE_JSON=$(
        curl --silent -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${OWNER}/${REPO}/releases/${RELEASE}" \
        || fail "Unable to get RELEASE_JSON from GitHub."
    )

    jq -r "
        .assets[]
        |
        select(.name | test(\"${REGEX}\"))
        |
        .browser_download_url
    " <(echo "${RELEASE_JSON}") \
        || fail "Unable to parse RELEASE_JSON."

}

###########################     Program selector     ###########################
if [[ "${PROGRAM}" == "git-credential-manager" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "GitCredentialManager" "${PROGRAM}" \
            "${VERSION}" \
            '.*gcm-linux_amd64.*.deb'
    )
    declare -r PACKAGE_FORMAT="deb"
elif [[ "${PROGRAM}" == "hadolint" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "${PROGRAM}" "${PROGRAM}" \
            "${VERSION}" \
            "hadolint-Linux-x86_64"
    )
    declare -r PACKAGE_FORMAT="bin"
elif [[ "${PROGRAM}" == "helm" ]]; then
    declare -r DOWNLOAD_URL="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
    declare -r PACKAGE_FORMAT="bash"
elif [[ "${PROGRAM}" == "helmfile" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "${PROGRAM}" "${PROGRAM}" \
            "${VERSION}"
    )
    declare -r PACKAGE_FORMAT="bin"
    declare -r INSTALL_FILE="${PROGRAM}"
elif [[ "${PROGRAM}" == "k3d" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "k3d-io" "${PROGRAM}" \
            "${VERSION}" \
            'k3d-linux-amd64'
    )
    declare -r PACKAGE_FORMAT="bin"
elif [[ "${PROGRAM}" == "kubectl" ]]; then
    if [[ "${ARG_VERSION}" == "latest" ]]; then
        KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
        declare -r KUBECTL_VERSION
    else
        declare -r KUBECTL_VERSION="${VERSION}"
    fi
    declare -r DOWNLOAD_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    declare -r PACKAGE_FORMAT="bin"
elif [[ "${PROGRAM}" == "nvm" ]]; then
    if [[ "${ARG_VERSION}" == "latest" ]]; then
        declare -r DOWNLOAD_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
    else
        declare -r DOWNLOAD_URL="https://raw.githubusercontent.com/nvm-sh/nvm/${VERSION}/install.sh"
    fi
    declare -r PACKAGE_FORMAT="bash"
elif [[ "${PROGRAM}" == "sops" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "mozilla" "${PROGRAM}" \
            "${VERSION}" \
            '.*_amd64.deb'
    )
    declare -r PACKAGE_FORMAT="deb"
elif [[ "${PROGRAM}" == "yq" ]]; then
    DOWNLOAD_URL=$(
        get_gh_release_url \
            "mikefarah" "${PROGRAM}" \
            "${VERSION}" \
            '.*_linux_amd64$'
    )
    declare -r PACKAGE_FORMAT="bin"
else
    fail "❌ ERROR: program ${PROGRAM} not supported."
fi
declare -r DOWNLOAD_URL

if [[ -n ${VERBOSE+x} ]]; then
    stderr ""
    stderr "Program Selector"
    stderr "  PROGRAM:        ${PROGRAM:-None}"
    stderr "  VERSION:        ${VERSION:-None}"
    stderr "  DOWNLOAD_URL:   ${DOWNLOAD_URL:-None}"
    stderr "  PACKAGE_FORMAT: ${PACKAGE_FORMAT:-None}"
    stderr "  INSTALL_FILE:   ${INSTALL_FILE:-None}"
    stderr ""
fi

###############################     Download     ###############################
DOWNLOAD_DIR=$(mktemp -d)
FILENAME=$(basename "${DOWNLOAD_URL}")
declare -r FILENAME

if [[ -n ${VERBOSE+x} ]]; then
    declare -r WGET_QUIET=''
else
    declare -r WGET_QUIET='--quiet'
fi

echo "⏳ Downloading ${PROGRAM} …"
if [[ "${FILENAME}" == *.tar.gz ]]; then
    wget "${WGET_QUIET}" -O - "${DOWNLOAD_URL}" | tar -xzC "${DOWNLOAD_DIR}" \
        || fail "Unable to download .tar.gz: ${DOWNLOAD_URL}"
else
    wget "${WGET_QUIET}" -O "${DOWNLOAD_DIR}/${FILENAME}" "${DOWNLOAD_URL}" \
        || fail "Unable to download: ${DOWNLOAD_URL}"
fi
echo "✅ Download complete!"

if [[ -n ${VERBOSE+x} ]]; then
    stderr ""
    stderr "Download"
    stderr "  DOWNLOAD_DIR: ${DOWNLOAD_DIR:-None}"
    stderr "  FILENAME:     ${FILENAME:-None}"
    stderr "  INSTALL_FILE: ${INSTALL_FILE:-None}"
    stderr ""
fi

###############################     Install     ###############################
echo "⌛ Installing ${PROGRAM} …"
if [[ "${PACKAGE_FORMAT}" == "bin" ]]; then
    sudo install "${DOWNLOAD_DIR}/${INSTALL_FILE:-${FILENAME}}" "/usr/local/bin/${PROGRAM}" \
        || fail "Unable to install executable ${DOWNLOAD_DIR}/${PROGRAM}"
elif [[ "${PACKAGE_FORMAT}" == "deb" ]]; then
    sudo chown -R _apt:root "${DOWNLOAD_DIR}"  # Not sure why, but apt has a warning when installing from $(mktemp -d) unless I chown it like so. https://askubuntu.com/a/1205517/80226
    sudo apt install "${DOWNLOAD_DIR}/${FILENAME}" \
        || fail "Unable to install deb ${DOWNLOAD_DIR}/${FILENAME}"
elif [[ "${PACKAGE_FORMAT}" == "bash" ]]; then
    if [[ "${PROGRAM}" == "helm" ]]; then
        if [[ "${ARG_VERSION}" != "latest" ]]; then
            declare -r HELM_VER="--version ${VERSION}"
        else
            declare -r HELM_VER=""
        fi
        bash "${DOWNLOAD_DIR}/${FILENAME}" "${HELM_VER}" \
            || fail "Unable to install Helm: ${DOWNLOAD_DIR}/${FILENAME}"
    else
        bash "${DOWNLOAD_DIR}/${FILENAME}" \
            || fail "Unable to install ${PROGRAM}: ${DOWNLOAD_DIR}/${FILENAME}"
    fi
else
    fail "ERROR: Package format was ${PACKAGE_FORMAT}  ¯\_(ツ)_/¯"
fi
echo "😀 Installation complete!"
