CNAME = pile

start:
	mkdir -p /svc/mnt/pile/pile /svc/mnt/pile/stack
	-sudo bindfs --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Pile/ /svc/mnt/pile/pile
	-sudo bindfs --create-for-user=100 --create-for-group=101 /share/hhartmann/attic/Stack/ /svc/mnt/pile/stack
	docker-compose up -d

stop:
	docker-compose down
	sudo umount /svc/mnt/pile/*
