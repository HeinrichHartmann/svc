URL=paperless.heinrichhartmann.net
include /svc/lib/include.mk

test:
	source /svc/lib/include.sh && check_url paperless.heinrichhartmann.net

fetch_mail:
	docker compose exec -it paperless mail_fetcher

backup:
	/svc/bin/backup backup /share/hhartmann/attic/Paperless-Originals
