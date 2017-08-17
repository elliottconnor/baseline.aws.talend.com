#!/usr/bin/env bash

set -e
set -u

[ "${CREATE_BUCKET_FLAG:-0}" -gt 0 ] && return 0

export CREATE_BUCKET_FLAG=1

create_bucket_script_path=$(readlink -e "${BASH_SOURCE[0]}")
create_bucket_script_dir="${create_bucket_script_path%/*}"

source "${create_bucket_script_dir}/../util/util.sh"
source "${create_bucket_script_dir}/../util/string_util.sh"

function create_bucket_usage() {

    cat 1>&2 <<-EOF

	create_bucket <bucket> [ <region> ]

	parameters:
	    bucket
	    region

	constraints:
	    aws s3 cli configured with credentials

	Create an arbitrary bucket

	EOF
}


function create_bucket() {

    if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
        create_bucket_usage
        return 0
    fi

    [ "${#}" -lt 1 ] && errorMessage "ERROR: invalid number of arguments '${#}'" && create_bucket_usage && return 1

    local bucket="${1}"
    lowercase bucket
    trim bucket

    [ -z "${bucket}" ]&& errorMessage "ERROR: invalid repo bucket name '${bucket}', repo bucket cannot be empty or blank" && return 1

    local region="${2:-${TALEND_FACTORY_REGION}}"

    [ -z "${region}" ] && region=$(aws configure get region)

    local -a regioncmd
    [ -n "${region}" ] && regioncmd=( "--region" "${region}" )

    local bucket_status
    bucket_status=$(aws s3api head-bucket --bucket "${bucket}" 2>&1)
    debugLog "bucket_status=${bucket_status}"
    string_contains "${bucket_status}" "Not Found" && bucket_exists=1 || bucket_exists=0
    debugLog "bucket_exists=${bucket_exists}"
    [ "${bucket_exists}" == 0 ] && [ -n "${bucket_status}" ] && errorMessage "Bucket ${bucket} is not writable: ${bucket_status}" && return 1

    [ "${bucket_exists}" != 0 ] && debugLog "creating bucket ${bucket}" && aws s3 mb "s3://${bucket}" "${regioncmd[@]}"

    debugLog "using existing bucket '${bucket}'"

    return 0
}
