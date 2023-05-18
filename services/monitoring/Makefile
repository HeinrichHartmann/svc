URL=grafana.heinrichhartmann.net prometheus.heinrichhartmann.net jaeger.heinrichhartmann.net influxdb.heinrichhartmann.net
include /svc/lib/include.mk

update-targets:
	sed -i '/SVC START/q' ./prometheus/pinghosts.yaml
	(cd /svc/services; grep -R HostRegexp \
		| sed -n -r 's/^.*[`](.*)[.][{].*$$/\1/p' \
		| sort | uniq \
		| sed -r 's|(.*)|    - https://\1.heinrichhartmann.net;\1;internal;internetbox|') \
		>> ./prometheus/pinghosts.yaml
	docker-compose restart prometheus
