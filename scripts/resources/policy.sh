#!/usr/bin/env bash

set -u

[ "${TALEND_FACTORY_FLAG:-0}" -gt 0 ] && return 0

export TALEND_FACTORY_FLAG=1

policy_script_path=$(readlink -e "${BASH_SOURCE[0]}")
policy_script_dir="${policy_script_path%/*}"

# shellcheck source=/home/ec2-user/talend-aws-baseline/scripts/util/util.sh
source "${policy_script_dir}/../util/util.sh"
# shellcheck source=/home/ec2-user/talend-aws-baseline/scripts/util/string_util.sh
source "${policy_script_dir}/../util/string_util.sh"


function policy_public_read_usage() {
    cat 1>&2 <<EOF

usage:
    policy_pubic_read <bucket> <policy_varname>

creates a policy for public BucketList and GetObject access

EOF
}

function policy_public_read() {

    [ "${#}" -ne 2 ] && errorMessage "invalid number of arguments '${#}' expected 2" && policy_public_read_usage && return 1

    local bucket="${1}"
    trim bucket
    [ -z "${bucket}" ] && errorMessage "invalid bucket '${bucket}', bucket must not be empty or blank" && policy_public_read_usage && return 1

    local policy_varname="${2}"
    trim policy_varname
    [ -z "${policy_varname}" ] && errorMessage "invalid policy variable '${policy_varname}', policy varname must not be empty or blank" && return 1

    define "${policy_varname}" <<EOF
{
    "Version": "2012-10-17",
    "Id": "Policy1502563323941",
    "Statement": [
        {
            "Sid": "Stmt1502563322940",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${bucket}/*"
        },
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${bucket}"
        }
    ]
}
EOF

}
