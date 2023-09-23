URL=etherpad.heinrichhartmann.net
include /svc/lib/include.mk

start:
	docker compose --env-file env.crypt up -d

stop:
	docker compose --env-file env.crypt down

clean:
	rm -rf /svc/var/etherpad
