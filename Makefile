startup: # called during book
	echo "Starting up..."
	make start

shutdown: # called during shutdown
	echo "Shutting down..."
	make stop

cron: # this is called every hour
	echo "Running cron..."
	# run docker updates at 2am
	if [[ $$(date +"%H") = "02" ]]; then make update; fi
	# run certbot on mondays at 2am
	if [[ $$(date +"%H") = "02" ]] &&  [[ $$(date +"%u") = "1" ]]; then make certs; fi
	# run cron target for in enabled services
	find -L ./services.enabled -type f -name "Makefile" \
	  -exec sh -c 'if grep -q "cron:" "{}"; then echo "Running cron in {}"; (cd $$(dirname "{}") && make cron); fi' \;

start:
	# We need to start these first
	cd services/traefik && make start
	cd services/docker && make start
	# Loop through all active services and start them
	for dir in services.enabled/*; do (cd "$$dir" && make start) & done; wait

stop:
	for dir in services.enabled/*; do (cd "$$dir" && make stop) & done; wait
	cd services/docker && make stop
	cd services/traefik && make stop

restart: stop start

umount:
	# lazy unmount of all nested mounts under /svc/mnt
	findmnt -r -o TARGET | grep '^/svc/mnt' | tac | xargs -n 1 sudo umount -l

stop-all:
	docker stop $$(docker ps -a -q)
	docker rm $$(docker ps -a -q)

update:
	for dir in services.enabled/*; do (cd "$$dir" && docker-compose pull; make restart) & done; wait

test:
	@cd services/traefik && make test
	@cd services/docker && make test
	@for dir in services.enabled/*; do (cd "$$dir" && make --silent --no-print-directory test); done

test-all:
	@for dir in services/*; do (cd "$$dir" && make test); done

prune:
	docker network prune -f # delete unused networks
	docker container prune -f # delete stopped containers
	docker image prune -a -f # delete unused images

certs:
	cd ./infrastructure/letsencrypt; nix develop --command make certs

.PHONY: install-deps
DEPS = gnupg \
       gnumake \
       git \
       git-crypt \
       openssl \
       findutils \
       dnsutils \
       dhcp \
       coreutils \
       poetry \
       awscli2 \
       jq \
       terraform \
       bindfs \
       imagemagick \
       parallel \
       restic
DEPS += postgresql # provides psql
DEPS += apacheHttpd # provides htpasswd

install-deps:
	$(foreach dep,$(DEPS),nix-env -iA nixos.$(dep);)

services-list:
	./svc.sh list

services-list-available:
	./svc.sh list-available
