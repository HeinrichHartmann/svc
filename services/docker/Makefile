URL=docker.heinrichhartmann.net dockercache.heinrichhartmann.net
include /svc/lib/include.mk

test:
	# list images
	curl -X GET https://docker.heinrichhartmann.net/v2/_catalog | jq .
	# pull an image
	docker pull docker.heinrichhartmann.net/pile
