#!/usr/bin/env sh

CNAME=homeassistant
INAME=ghcr.io/home-assistant/home-assistant:stable
TRAEFIK="traefik.http.routers.$CNAME"

docker pull "$INAME"
docker stop "$CNAME"
docker rm "$CNAME"
docker run --name "$CNAME" \
       --label "$TRAEFIK.rule="'HostRegexp(`homeassistant.{domain:.*}`)' \
       --label "$TRAEFIK.entrypoints=https" \
       --label "$TRAEFIK.tls=true" \
       --label 'traefik.enable=true' \
       --label "traefik.http.services.homeassistant.loadbalancer.server.port=8123" \
       -d --restart unless-stopped \
       -e TZ=CET \
       -v $(pwd)/config:/config \
       "$INAME"
