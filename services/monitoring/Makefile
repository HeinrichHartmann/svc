URL=grafana.heinrichhartmann.net prometheus.heinrichhartmann.net jaeger.heinrichhartmann.net influxdb.heinrichhartmann.net
include /svc/lib/include.mk

cron:
	# populate pinghosts.yaml with active HTTP services
	sed -i '/SVC START/q' ./prometheus/pinghosts.yaml
	(cd /svc/services; grep -R HostRegexp \
		| sed -n -r 's/^.*[`](.*)[.][{].*$$/\1/p' \
		| grep -v "%" \
		| sort | uniq \
		| sed -r 's|(.*)|    - https://\1.heinrichhartmann.net;\1;internal|') \
		>> ./prometheus/pinghosts.yaml
	docker compose kill -s SIGHUP prometheus
