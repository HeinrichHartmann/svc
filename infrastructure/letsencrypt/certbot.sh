#!/usr/bin/env bash

poetry run certbot --work-dir=/svc/var/letsencrypt/work --logs-dir=/svc/var/letsencrypt/log --config-dir=/svc/var/letsencrypt/config $@
