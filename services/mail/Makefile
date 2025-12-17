.PHONY: build sync start stop

build:
	nix build .#dockerImage
	docker load < result

sync:
	docker compose run --rm mbsync

start:
	@echo "mbsync is a one-shot service. Use 'make sync' to run it."

stop:
	@echo "Nothing to stop - mbsync runs and exits."

clean:
	docker compose down
	rm -f result
