#!/usr/bin/env bash

set -e
#set -x
set -u

# must be run from s3fs directory

sudo yum -y install automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

if [ ! -f autogen.sh ]; then
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse
else
    echo "INFO: s3fs found" 1>&2
fi

./autogen.sh
./configure
make
sudo make install

sudo ln -s /usr/local/bin/s3fs /usr/bin/s3fs

echo "INFO: s3fs-build: succes" 1>&2
