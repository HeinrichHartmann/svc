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

mount:
	mkdir -p /svc/mnt/jupyter
	mkdir -p /svc/mnt/jupyter/Finanzen
	bindfs -u 1000 -g 100 --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Finanzen /svc/mnt/jupyter/Finanzen

umount:
	-umount /svc/mnt/jupyter/*
