DELAY ?= 0
COMPOSEFILE=docker-compose.yaml

start:
	docker compose -f $(COMPOSEFILE) --ansi never up -d

stop:
	docker compose  -f $(COMPOSEFILE) --ansi never down

restart: stop start
	# kick traefik
	docker restart traefik

logs:
	docker compose  -f $(COMPOSEFILE) logs -f

test:
	# Check all targets in URL=a.com b.com
	source /svc/lib/include.sh && for url in $(URL); do check_url $$url; done

update:
	docker compose  -f $(COMPOSEFILE) pull -q
