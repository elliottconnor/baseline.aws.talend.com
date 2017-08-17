#!/usr/bin/env bash

set -e
set -u

s3_bucket="${1:-talend-quickstart-repo}"
s3_path="${2:-/}"
s3_mount="${3:-/opt/repo}"
s3_mount_root="${4:-${s3_mount}}"
s3fs_umask="${5:-037}"
sudo mkdir -p "${s3_mount}"
sudo chown -R "${USER}:${USER}" "${s3_mount_root}"
[ -n "${s3_path}" ] && [ "${s3_path:0:1}" != "/" ] && s3_path="/${s3_path}"
[ -n "${s3_path}" ] && s3_path=":${s3_path}"

# necessary because s3fs may not be on the path, even when sudo -E
s3fs_command="s3fs"
if [ ! "$(which ${s3fs_command})" ]; then
    [ ! -f "/usr/local/bin/s3fs" ] && echo "could not find s3fs command" 1>&2 && exit 1
    s3fs_command="/usr/local/bin/s3fs"
fi
echo "${s3fs_command}" "${s3_bucket}${s3_path}" "${s3_mount}" -o allow_other -o mp_umask="${s3fs_umask}" 1>&2
"${s3fs_command}" "${s3_bucket}${s3_path}" "${s3_mount}" -o allow_other -o mp_umask="${s3fs_umask}"
echo "INFO: s3fs-mount: ${s3_bucket} to ${s3_mount} umask ${s3fs_umask}" 1>&2
