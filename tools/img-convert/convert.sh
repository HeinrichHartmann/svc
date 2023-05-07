#!/usr/bin/env sh

mkdir -p camera-upload
sudo bindfs -u $(id -u) --create-for-user=100 --create-for-group=101 /share/hhartmann/garage/camera-upload ./camera-upload

while true
do
    find camera-upload/ -name '*.HEIC' -print0 | parallel -0 --line-buffer -q bash -c 'echo "{} ..." && convert "{}" "{.}.png" && rm "{}"'
    printf "Done. Sleeping.\n"
    sleep 3600
done
