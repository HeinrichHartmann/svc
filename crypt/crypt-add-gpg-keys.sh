#!/usr/bin/env bash
set -euo pipefail

for key in gpg/*.key
do
    gpg --import "$key"
done

for id in gpg/*.id
do
    git-crypt add-gpg-user --trusted "$(cat "$id")"
done
