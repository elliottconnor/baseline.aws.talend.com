#!/usr/bin/env bash

set -e
set -u

[ "${TALEND_FACTORY_FLAG:-0}" -gt 0 ] && return 0

export TALEND_FACTORY_FLAG=1

build_script_path=$(readlink -e "${BASH_SOURCE[0]}")
build_script_dir="${build_script_path%/*}"

source "${build_script_dir}/../util/util.sh"
source "${build_script_dir}/../util/string_util.sh"
source "${build_script_dir}/../s3-deploy/git-deploy.sh"
source "${build_script_dir}/../s3-deploy/s3-sync.sh"
source "${build_script_dir}/../s3fs/s3fs-util.sh"
source "${build_script_dir}/create-bucket.sh"
source "${build_script_dir}/create-repo-bucket.sh"
source "${build_script_dir}/create-license-bucket.sh"

# TODO:

# option on step 2
# Load License


function talend_factory_usage() {
    cat 1>&2 <<-EOF

# Step-1 License bucket
#
# Inputs: s3 credentials, Talend license
#
#Create license-bucket (license.talend.com)
#Load license to license-bucket
#[Create cross-account IAM roles and policies]

# Step-2 Talend Baseline bucket
#
# Inputs: s3 credentials 
#
#Create talend-baseline bucket (baseline.aws.talend.com)
#Publish talend-aws-baseline github to talend-baseline bucket
#[Grant public access to talend-templates bucket]

# Step-3 Talend Quickstart
#
# Inputs: s3 credentials 
#
#Create talend-quickstart bucket (quickstart.talend.com)
#Publish talend-aws-quickstart github to talend-quickstart bucket
#
# Step-4 Binary Repo bucket
#
# Inputs: s3 credentials, local TUI, Talend credentials
#
# Create talend-repo bucket (talend-quickstart-repo)
# Note that this name cannot have any ‘.’s (periods) in it since it will be mounted with s3fs
#
# Unzip TUI
# Download license from license-bucket
# Configure TUI with license
# Configure TUI with Talend Credentials
# Download s3fs from talend-templates
# Build s3fs
# Mount talend-repo
# Run TUI download to talend-repo
# Copy TUI to talend-repo mount
# Copy JRE to talend-repo mount

	EOF
}


function talend_factory_setup() {

    sudo "${build_script_dir}/../bootstrap/update_hosts.sh"
    sudo "${build_script_dir}/../java/jre-installer.sh"
    source /etc/profile.d/jre.sh

}


function build_repo_download() {
    local url="${1:-}"

    string_begins_with "${url}" "s3:" && aws s3 cp "${url}" . && return 0

    string_begins_with "${url}" "http" && wget "${url}" && return 0

    [ -f "${url}" ] && return 0

    return 1
}

function build_repo() {

    local access_key="${1:-${access_key:-${TALEND_FACTORY_ACCESS_KEY:-}}}"
    local secret_key="${2:-${secret_key:-${TALEND_FACTORY_SECRET_KEY:-}}}"
    local talend_userid="${3:-${talend_userid:-${TALEND_FACTORY_TALEND_USERID:-}}}"
    local talend_password="${4:-${talend_password:-${TALEND_FACTORY_TALEND_PASSWORD:-}}}"
    local license_file_path="${5:-${license_file_path:-license}}"
    local tui_file_path="${6:-${tui_path:-TUI-4.5.2}}"
    local tui_profile="${7:-${tui_profile:-${TALEND_FACTORY_TUI_PROFILE:-quickstart}}}"
    local repo_bucket="${8:-${repo_bucket:-${TALEND_FACTORY_REPO_BUCKET:-}}}"
    local repo_path="${9:-${repo_path:-${TALEND_FACTORY_REPO_PATH:-/}}}"
    local repo_mount_dir="${10:-${repo_mount_dir:-${TALEND_FACTORY_REPO_MOUNT_DIR:-/opt/repo}}}"

    local tui_filename="${tui_path##*/}"
    local tui_dir="${tui_filename%.*}"

    tar xvpf "${tui_filename}"
    cp -rf "${build_script_dir}"/../../tui/conf/* "${tui_dir}/conf"

    cp "${license_file_path}" "${tui_dir}/licenses/6.3.1"


    cat > "${tui_dir}/licenses/6.3.1/download_credentials.properties" <<EOF
TALEND_DOWNLOAD_USER=${talend_userid}
TALEND_DOWNLOAD_PASSWORD=${talend_password}
EOF

    try s3fs_build
    try s3fs_config "${access_key}" "${secret_key}"
    try s3fs_mount "${repo_bucket}" "${repo_path}" "${repo_mount_dir}"

    "${tui_dir}/install" -q -d "${tui_profile}"
    local tui_target_dir="${repo_mount_dir}/tui"
    mkdir -p "${tui_target_dir}"
    cp "${tui_filename}" "${tui_target_dir}"
    try s3fs_dir_attrib "ec2-user" "${repo_mount_dir}"

    # TODO: find a better way to address this
    # chmod u+x "${repo_mount_dir}/scripts/0.0.9/ec2-metadata"
    # chmod g+x "${repo_mount_dir}/scripts/0.0.9/ec2-metadata"
}
}



function talend_factory() {

    if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
        talend_factory_usage
        return 0
    fi

    local access_key="${1:-${access_key:-${TALEND_FACTORY_ACCESS_KEY:-}}}"
    local secret_key="${2:-${secret_key:-${TALEND_FACTORY_SECRET_KEY:-}}}"

    local talend_userid="${3:-${talend_userid:-${TALEND_FACTORY_TALEND_USERID:-}}}"
    local talend_password="${4:-${talend_password:-${TALEND_FACTORY_TALEND_PASSWORD:-}}}"

    local license_path="${5:-${license_path:-${TALEND_FACTORY_LICENSE_PATH:-}}}"
    local tui_path="${6:-${tui_path:-${TALEND_FACTORY_TUI_PATH:-}}}"
    local tui_profile="${7:-${tui_profile:-${TALEND_FACTORY_TUI_PROFILE:-quickstart}}}"

    local repo_bucket="${8:-${repo_bucket:-${TALEND_FACTORY_REPO_BUCKET:-}}}"
    local repo_path="${9:-${repo_path:-${TALEND_FACTORY_REPO_PATH:-/}}}"
    local repo_mount_dir="${10:-${repo_mount_dir:-${TALEND_FACTORY_REPO_MOUNT_DIR:-/opt/repo}}}"
    local license_bucket="${11:-${license_bucket:-${TALEND_FACTORY_LICENSE_BUCKET:-}}}"
    local license_owner="${12:-${license_owner:-${TALEND_FACTORY_LICENSE_OWNER:-}}}"
    local baseline_bucket="${13:-${baseline_bucket:-${TALEND_FACTORY_BASELINE_BUCKET:-}}}"
    local quickstart_bucket="${14:-${quickstart_bucket:-${TALEND_FACTORY_QUICKSTART_BUCKET:-}}}"

    [ -z "${license_path}" ] && errorMessage "license path required" && return 1
    [ ! -f "${license_path}" ] && errorMessage "license path '${license_path}' does not exist" && return 1

    try build_repo_download "${license_path}"
    local license_file_path
    license_file_path="$(pwd)/license"

    try create_license_bucket "${license_owner}" "${license_bucket}"
    aws s3 cp "${license_file_path}" "s3://${license_bucket}"

    try create_bucket "${baseline_bucket}"
    try s3_deploy "${build_script_dir}/../resources/talend-baseline-env"

    try create_bucket "${quickstart_bucket}"
    try s3_deploy "${build_script_dir}/../resources/talend-quickstart-env"

    try build_repo_download "${tui_path}"
    local tui_filename="${tui_path##*/}"
    local tui_file_path
    tui_file_path="$(pwd)/${tui_filename}"

    try create_repo_bucket "${repo_bucket}"
    try build_repo "${access_key}" "${secret_key}" \
                   "${talend_userid}" "${talend_password}" \
                   "${license_file_path}" \
                   "${tui_file_path}" "${tui_profile}" \
                   "${repo_bucket}" "${repo_path}" \
                   "${repo_mount_dir}"
}

