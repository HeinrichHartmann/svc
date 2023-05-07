#!/bin/bash

CNAME=pile
INAME=docker.heinrichhartmann.net/pile
TRAEFIK="traefik.http.routers.$CNAME"

mkdir -p data/pile
sudo bindfs -u $(id -u) --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Pile/ ./data/pile

mkdir -p data/stack
sudo bindfs -u $(id -u)  --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Stack/ ./data/stack

docker stop $CNAME || true
docker rm $CNAME || true
docker pull $INAME || true
docker run -d --restart unless-stopped --name $CNAME \
    -v $(pwd)/data/pile:/pile/data/pile \
    -v $(pwd)/data/stack:/pile/data/stack \
    --label "$TRAEFIK.rule="'HostRegexp(`pile.{domain:.*}`)' \
    --label "$TRAEFIK.entrypoints=https" \
    --label "$TRAEFIK.tls=true" \
    --label "$TRAEFIK.middlewares=auth@file" \
    --label 'traefik.enable=true' \
    $INAME \
    piled
