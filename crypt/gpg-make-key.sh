#!/usr/bin/env bash
#: Date : 2021-10-10

set -o errexit
set -o nounset
set -o pipefail

# return if we already have a key for this host
if gpg --list-secret-keys "$(hostname)" > /dev/null;
then
   printf "%s\n" "Found existing keys"
else
    set -x
    cat gpg-gen-script.tpl \
        | sed "s/%COMMENT%/$(hostname)/" \
        | sed "s/%NAME%/$(id -u -n)/" \
        > gpg-gen-script.tmp
    gpg --batch --passphrase '' --gen-key gpg-gen-script.tmp
    rm gpg-gen-script.tmp
fi
