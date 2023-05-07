#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o noclobber

CNAME=gogs
INAME=gogs/gogs
TRAEFIK="traefik.http.routers.$CNAME"

set -x

# fix permissions
#sudo chown 1000:1000 -R /share/hhartmann/gogs

docker stop $CNAME || true
docker rm $CNAME || true
docker pull $INAME || true
docker run -d --restart unless-stopped --name $CNAME \
       -p 0.0.0.0:2222:2222 \
       --label "$TRAEFIK.rule="'HostRegexp(`gogs.{domain:.*}`)' \
       --label "$TRAEFIK.entrypoints=https" \
       --label "traefik.http.services.gogs.loadbalancer.server.port=3000" \
       --label "$TRAEFIK.tls=true" \
       --label 'traefik.enable=true' \
       -v /share/hhartmann/gogs:/data \
       $INAME
