IMAGE=docker.heinrichhartmann.net/hh-jupyter

start:
	docker-compose up -d

stop:
	docker-compose down

test:
	source /svc/lib/include.sh && check_url jupyter.heinrichhartmann.net

build:
	docker build . -t $(IMAGE) --no-cache

push:
	docker push $(IMAGE)
