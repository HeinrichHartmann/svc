#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o noclobber

set -x

while true;
do
    # Trigger backup first
    just backup-raw

    # Wait 5 minutes before prune (allows inspection/interrupt)
    echo "Backup complete. Waiting 5 minutes before prune..."
    sleep 300

    # Perform Maintenance
    just prune-raw

    # Sleep until next backup interval
    interval="tomorrow 03:00:00"
    sleep_time="$(expr $(date -d "$interval" +%s) - $(date +%s))"
    echo Sleeping until $interval: $sleep_time seconds
    sleep $sleep_time
done
