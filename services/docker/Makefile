start:
	docker-compose up -d

stop:
	docker-compose down

test:
	source /svc/lib/include.sh && check_url docker.heinrichhartmann.net/v2/_catalog
	source /svc/lib/include.sh && check_url dockercache.heinrichhartmann.net/v2/_catalog
