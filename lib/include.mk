DELAY ?= 0

start:
	docker compose --ansi never up -d

stop:
	docker compose --ansi never down

restart: stop start
	# kick traefik
	docker restart traefik

logs:
	docker compose logs -f

test:
	# Check all targets in URL=a.com b.com
	source /svc/lib/include.sh && for url in $(URL); do check_url $$url; done

update:
	docker compose pull -q
