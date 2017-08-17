#!/usr/bin/env bash

set -e
set -u

source util.sh

errorMessage "some error"

function myfunc() {

    echo "a"
    return 1
}

try myfunc a
