#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o noclobber

set -x

while true;
do
    # Trigger an immediate backup now
    echo "[$(date)] Running backup"
    restic --cache-dir=/cache --host pve --repo b2:hh-restic-b2 -v backup /share/shelf
    restic --cache-dir=/cache --host pve --repo b2:hh-restic-b2 -v backup /share/attic

    # Sleep until next bakup interval
    interval="tomorrow 03:00:00"
    sleep_time="$(expr $(date -d "$interval" +%s) - $(date +%s))"
    echo Sleeping until $interval: $sleep_time seconds
    sleep $sleep_time
done
