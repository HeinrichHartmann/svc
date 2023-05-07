#!/usr/bin/env bash

gpg --list-keys --keyid-format LONG  "$(hostname)" | grep pub | sed -nr 's|.*rsa.*/([^ ]*)[ ].*$|\1|p' > "gpg/gpg-$(hostname).id"
gpg --export -a "$(hostname)" > "gpg/gpg-$(hostname).key"

git add "gpg/gpg-$(hostname).key" "gpg/gpg-$(hostname).id"
git commit -m "Add gpg-$(hostname)"
