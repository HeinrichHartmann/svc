start:
	mkdir -p /svc/mnt/wiki
	-sudo bindfs -m root --create-for-user=1000 --create-for-group=1000 /share/hhartmann/var/gogs/git/gogs-repositories/hhartmann/wiki.git /svc/mnt/wiki/
	docker-compose up -d

stop:
	docker-compose down
	sudo umount /svc/mnt/wiki/
