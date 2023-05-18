URL=jupyter.heinrichhartmann.net
IMAGE=docker.heinrichhartmann.net/hh-jupyter

include /svc/lib/include.mk

build:
	docker build . -t $(IMAGE) --no-cache

push:
	docker push $(IMAGE)
