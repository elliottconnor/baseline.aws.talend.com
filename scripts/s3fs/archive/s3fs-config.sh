#!/usr/bin/env bash

set -e
# set -x
set -u

[ "${#}" -ne 2 ] && echo "access key and secret key arguments are required" 1>&2 && exit 1

access_key="${1}"
secret_key="${2}"

[ -z "${access_key}" ] || [ -z "${secret_key}" ] && echo "access key and secret key must not be blank" 1>&2 && exit 1

credentials_file=~/.passwd-s3fs
sudo sed -i "s/# user_allow_other/user_allow_other/g" /etc/fuse.conf

if [ -n "${access_key}" ] && [ -n "${secret_key}" ]; then
    echo "${access_key}:${secret_key}" > "${credentials_file}"
    chmod 600 "${credentials_file}"
elif [ ! -f "${credentials_file}" ]; then
    echo "ERROR: credential file ${credentials_file} must be set." 1>&2
    exit 1
else
    # credentials_file will be generated by cloud formation
    echo "INFO: credential file ${credentials_file} found." 1>&2
fi

echo "INFO: s3fs-config: succes" 1>&2