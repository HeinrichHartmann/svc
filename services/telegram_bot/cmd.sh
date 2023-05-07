#!/bin/bash

while true
do
  printf "pull %s\n" $(date +"%FT%T%Z")
  telegram_bot pull $TOKEN
  sleep 60
done
