#!/usr/bin/env bash

# prepare a mount point wth correct ownership rules
# must be run as sudo

set -e
#set -x
set -u

target_owner="ec2-user"
mount_dir="/opt/repo"

mydir_list=$(ls -d "${mount_dir}"/*/)
for subdir in ${mydir_list}
do
    echo "processing ${subdir}"
    chown "${target_owner}:${target_owner}" "${subdir}"
    chmod 750 "${subdir}"
    find "${subdir}" -type d -exec chown "${target_owner}:${target_owner}" {} \;
    find "${subdir}" -type d -exec chmod 750 {} \;
    find "${subdir}" -type f -name "*" -exec chown "${target_owner}:${target_owner}" {} \;
    find "${subdir}" -type f -name "*" -exec chmod 440 {} \;
    find "${subdir}" -type f -name "*.sh" -exec chmod 550 {} \;
done

chmod u+x "${mount_dir}/scripts/0.0.9/ec2-metadata"
chmod g+x "${mount_dir}/scripts/0.0.9/ec2-metadata"
