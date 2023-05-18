URL=wiki.heinrichhartmann.net
include /svc/lib/include.mk

mount:
	mkdir -p /svc/mnt/wiki
	-sudo bindfs -m root --create-for-user=1000 --create-for-group=1000 /share/hhartmann/var/gogs/git/gogs-repositories/hhartmann/wiki.git /svc/mnt/wiki/

umount:
	sudo umount /svc/mnt/wiki/
