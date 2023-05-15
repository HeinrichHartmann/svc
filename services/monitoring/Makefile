start:
	docker-compose up -d

stop:
	docker-compose down

test:
	@source /svc/lib/include.sh && check_url grafana.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url prometheus.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url jaeger.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url influxdb.heinrichhartmann.net

update-targets:
	sed -i '/SVC START/q' ./prometheus/pinghosts.yaml
	(cd /svc/services; grep -R HostRegexp \
		| sed -n -r 's/^.*[`](.*)[.][{].*$$/\1/p' \
		| sort | uniq \
		| sed -r 's|(.*)|    - https://\1.heinrichhartmann.net;\1;internal;internetbox|') \
		>> ./prometheus/pinghosts.yaml
	docker-compose restart prometheus
