include /svc/lib/include.mk

.PHONY: build sync start stop job-run

build:
	nix build .#dockerImage
	docker load < result

start:
	@echo "mbsync is a one-shot service. Use 'make sync' to run it."

stop:
	@echo "Nothing to stop - mbsync runs and exits."

clean:
	docker compose down
	rm -f result

job-run:
	./scripts/sync.rb
