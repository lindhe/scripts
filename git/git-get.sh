#!/usr/bin/env bash

# This script makes it easier to clone a git repo from e.g. Github and put it in
# a directory according to the repo owner in the URL.

# Input arguments
repo_url="${1}"

# Environment variables
GIT_LOCATION="${GLOBAL_GIT_LOCATION:-$HOME/git}"

repo_owner=$(echo $repo_url | sed -E 's#https?://##' | cut -d '/' -f 2)
repo_name=$(echo $repo_url | sed -E 's#https?://##' | cut -d '/' -f 3)
repo_target_path="${GIT_LOCATION}/${repo_owner}/${repo_name%.git}"

mkdir -p ${repo_target_path}

git clone "${repo_url}" "${repo_target_path}"
