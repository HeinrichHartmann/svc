#!/usr/bin/env sh

check_url() {
    url=$1
    retries=${2:-10}
    for i in $(seq 1 $retries); do
        status=$(curl -L -s -o /dev/null -w "%{http_code}" $url)
        if [ $status -eq 200 ]; then
            echo "OK $url" >&2
            return 0
        elif [ $status -eq 401 ]; then
            echo "OK (UNAUTHORIZED) $url" >&2
            return 0
        else
            echo "." >&2
            sleep 1s
        fi
    done
    echo "FAILED $url" >&2
    return 1
}
