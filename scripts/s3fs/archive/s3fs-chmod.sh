#!/usr/bin/env bash

set -e
# set -x
set -u

filepath="${1}"
perm="${2:-640}"
owner="${3:-ec2-user}"
sudo chown "${owner}:${owner}" "${filepath}"
chmod "${perm}" "${filepath}"

echo "s3fs-chmod: ${filepath} ${owner}:${owner} ${perm}" 1>&2
