#!/usr/bin/env bash

set -e
set -u

[ "${#}" -ne 1 ] && echo "usage: isTalendStarted <tacHostname>" && exit 1


tacHostname="${1}"
tacPort="${2:-8080}"
tacPath="${3:-tac}"

echo "$(date +%Y-%m-%d:%H:%M:%S) --- checking TAC status..." 1>&2
until [ "`wget -O - --timeout=10 http://${tacHostname}:${tacPort}/${tacPath} | tee -a /home/ec2-user/isTACStarted.log | grep 'noscript'`" != "" ]; do
    echo "$(date +%Y-%m-%d:%H:%M:%S) --- sleeping for 10 seconds before checking http://${tacHostname}:${tacPort}/${tacPath}" | tee -a /home/ec2-user/isTACStarted.log
    sleep 10
done
echo "$(date +%Y-%m-%d:%H:%M:%S) --- TAC is ready!  http://${tacHostname}:${tacPort}/${tacPath}" | tee -a /home/ec2-user/isTACStarted.log 1>&2
