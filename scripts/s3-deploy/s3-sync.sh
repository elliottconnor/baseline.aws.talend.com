#!/usr/bin/env bash

set -e
set -u

export S3_SYNC_FLAG
[ "${S3_SYNC_FLAG:-0}" -gt 0 ] && return 0

export S3_SYNC_FLAG=1

s3_sync_script_path=$(readlink -e "${BASH_SOURCE[0]}")
s3_sync_script_dir="${s3_sync_script_path%/*}"

source "${s3_sync_script_dir}/../util/util.sh"
source "${s3_sync_script_dir}/../util/string_util.sh"


function s3_sync_usage() {
    cat 1>&2 <<-EOF

	s3-sync.sh

	usage:
	    ./s3-sync.sh [ <deploy_dir> [ <s3_bucket> [ <s3_path> [ <s3_grant> ] ] ] ]

	    deploy_dir: GIT_DEPLOY_DIR (aws-quickstart-master)
	    s3_bucket: GIT_DEPLOY_S3_BUCKET (talend-quickstart)
	    s3_path: GIT_DEPLOY_S3_PATH (empty string)
	    s3_grant: GIT_DEPLOY_GRANT (empty string)
	EOF
}

function s3_sync() {

    if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
        s3_sync_usage
        return 0
    fi

    local deploy_dir="${1:-${GIT_DEPLOY_DIR:-${GIT_DEPLOY_REPO}-${GIT_DEPLOY_TARGET}}}"

    [ "${deploy_dir}" == "-" ] && errorMessage "deploy_dir argument must be specified or GIT_DEPLOY and GIT_DEPLOY_TARGET environment variables set" && s3_sync_usage && return 1

    local s3_bucket="${2:-${GIT_DEPLOY_S3_BUCKET:-s3://talend-quickstart}}"

    # if s3_path is not empty it should begin with a /
    s3_path="${3:-${GIT_DEPLOY_S3_PATH}}"

    local s3_grant="${4:-${GIT_DEPLOY_GRANT}}"

    local -a grantcmd
    [ -n "${s3_grant}" ] && grantcmd=( "--grant" "${s3_grant}" )

    debugLog "invoking aws s3 sync from $(pwd)"
    aws s3 sync "${deploy_dir}" "s3://${s3_bucket}${s3_path}" --delete --exclude '.git/*' "${grantcmd[@]}"
}
