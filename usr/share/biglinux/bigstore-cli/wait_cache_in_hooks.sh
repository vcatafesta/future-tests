#!/usr/bin/env bash

# Wait Big Store cache limited in 30 seconds
declare -i waitCount=0

# Wait limit in 30 seconds
while [ $waitCount -lt 150 ]; do
    if ! ps -x | grep -q '[b]ash /usr/share/biglinux/bigstore-cli/update-cache.sh Running Hooks'; then
        exit 0
    fi

    waitCount++
    sleep 0.2
done
