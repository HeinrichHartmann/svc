#!/usr/bin/env bash

poetry run certbot --work-dir=/share/hhartmann/var/letsencrypt/work --logs-dir=/share/hhartmann/var/letsencrypt/log --config-dir=/share/hhartmann/var/letsencrypt/config $@
