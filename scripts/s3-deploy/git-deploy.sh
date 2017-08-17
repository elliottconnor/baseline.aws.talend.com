#!/usr/bin/env bash

export GIT_DEPLOY_FLAG
[ "${GIT_DEPLOY_FLAG:-0}" -gt 0 ] && return 0

export GIT_DEPLOY_FLAG=1

set -e
set -u
#set -x


git_deploy_script_path=$(readlink -e "${BASH_SOURCE[0]}")
git_deploy_script_dir="${git_deploy_script_path%/*}"

source "${git_deploy_script_dir}/../util/util.sh"
source "${git_deploy_script_dir}/../util/string_util.sh"

function git_deploy_usage() {
    cat 1>&2 <<-EOF

	git-get

	usage:
	    ./git-get.sh [ <target> [ <git_repo> [ <git_url> [ <deploy_dir> ] ] ] ]

	    target: GIT_DEPLOY_TARGET (master) git tag or branch
	    git_repo: GIT_DEPLOY_REPO (aws-quickstart)
	    git_url: GIT_DEPLOY_HUB (https://github.com/EdwardOst)
	    deploy_dir: GIT_DEPLOY_DIR (aws-quickstart-master)
	EOF
}


function git_deploy() {

    if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
        git_deploy_usage
        return 0
    fi

    # target is either a tag name or remote branch name
    local target="${1:-${GIT_DEPLOY_TARGET:-master}}"

    local git_repo="${2:-${GIT_DEPLOY_REPO:-aws-quickstart}}"

    local git_url="${3:-${GIT_DEPLOY_HUB:-https://github.com/EdwardOst}}"

    local deploy_dir="${4:-${GIT_DEPLOY_DIR:-${git_repo}-${target}}}"

    local cloned=false
    [ ! -d "${deploy_dir}" ] && cloned=true && git clone "${git_url}/${git_repo}" "${deploy_dir}"

    try pushd "${deploy_dir}"

    if [ "${cloned}" != "true" ]; then
        # Abort on changes to tracked files
        debugLog "Checking for changes to tracked files"
        git diff --quiet || errorMessage "changes to tracked files detected" || return 1

       # Aborting on finding untracked files
       debugLog "Checking for untracked files"
       git ls-files -o || errorMessage "untracked files detected" || return 1
    fi

    git fetch --all
    git checkout --force "${target}"

    # Following two lines only required if you use submodules
    git submodule sync || true
    git submodule update --init --recursive || true

    try popd
}
