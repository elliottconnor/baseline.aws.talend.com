#!/usr/bin/env bash

export S3_DEPLOY_FLAG
[ "${S3_DEPLOY_FLAG:-0}" -gt 0 ] && return 0

export S3_DEPLOY_FLAG=1

set -e
set -u
#set -x

s3_deploy_script_path=$(readlink -e "${BASH_SOURCE[0]}")
s3_deploy_script_dir="${s3_deploy_script_path%/*}"

source "${s3_deploy_script_dir}/../util/util.sh"
source "${s3_deploy_script_dir}/git-deploy.sh"
source "${s3_deploy_script_dir}/s3-sync.sh"

function s3_deploy() {

    local deploy_env="${1:-}"
    [ -f "${deploy_env}" ] && source "${deploy_env}"

    git_deploy

    s3_sync
}
