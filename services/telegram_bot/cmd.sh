#!/bin/bash

while true
do
  printf "pull %s\n" $(date +"%FT%T%Z")
  telegram_bot pull $TOKEN && touch /tmp/heartbeat
  sleep 60
done
