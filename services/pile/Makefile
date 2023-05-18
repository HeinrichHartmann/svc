URL=pile.heinrichhartmann.net
include /svc/lib/include.mk

mount:
	mkdir -p /svc/mnt/pile/pile /svc/mnt/pile/stack
	-sudo bindfs --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Pile/ /svc/mnt/pile/pile
	-sudo bindfs --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Stack/ /svc/mnt/pile/stack

umount:
	docker-compose down
	sudo umount /svc/mnt/pile/*
