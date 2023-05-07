start:
	docker-compose up -d

stop:
	docker-compose down

test:
	@source /svc/lib/include.sh && check_url grafana.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url prometheus.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url jaeger.heinrichhartmann.net
	@source /svc/lib/include.sh && check_url influxdb.heinrichhartmann.net
	#@source /svc/lib/include.sh && check_url cadvisor.heinrichhartmann.net
