#!/usr/bin/env bash

set -e
set -u

[ "${UTIL_FLAG:-0}" -gt 0 ] && return 0

export UTIL_FLAG=1


# read here documents into a variable
# then use a here string to access it elsewhere
#
# define myvar <<EOF
# the quick brown fox jumped over the lazy dog
# EOF
#
# grep -q "txt" <<< "$myvar"
#

define(){ IFS=$'\n' read -r -d '' "${1}" || true; }


function errorMessage() { 
    echo "$0: ${FUNCNAME[*]}: ${*}" 1>&2
}

function debugLog() { 
    [ -n "${DEBUG_LOG:-}" ] && echo "${FUNCNAME[*]}: ${*}" 1>&2
    return 0
}

function debugVar() {
    [ -n "${DEBUG_LOG:-}" ] && echo "${FUNCNAME[*]}: ${1}=${!1}" 1>&2
    return 0
}

function debugStack() {
    if [ -n "${DEBUG_LOG:-}" ] ; then
        local args
        [ "${#}" -gt 0 ] && args=": $*"
        echo "debug: ${FUNCNAME[*]}${args}" 1>&2
    fi
}

function die() {
    errorMessage "$*"
    exit 1
}


function try() {
    "$@" || die "cannot $*"
}
