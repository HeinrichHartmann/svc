URL=jupyter.heinrichhartmann.net
IMAGE=docker.heinrichhartmann.net/hh-jupyter

include /svc/lib/include.mk

build:
	docker build . -t $(IMAGE) --no-cache
	docker push $(IMAGE)

push:
	docker push $(IMAGE)

update: build
	docker compose pull -q
