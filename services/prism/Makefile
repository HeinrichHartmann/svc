URL=prism.heinrichhartmann.net
include /svc/lib/include.mk

mount:
	#
	# Photo Library / Originals
	#
	mkdir -p /svc/mnt/prism/pictures
	sudo bindfs -u 1000 -operms=a-w /share/hhartmann/garage/Pictures/Prism/ \
	  /svc/mnt/prism/pictures

	mkdir -p /svc/mnt/prism/pictures/attic
	sudo bindfs -u 1000 -operms=a-w /share/hhartmann/attic/Pictures/ \
	  /svc/mnt/prism/pictures/attic

	#
	# Import folders
	#
	mkdir -p /svc/mnt/prism/import/camera-upload
	sudo bindfs -u 1000 --create-for-user=100 --create-for-group=101 /share/hhartmann/garage/camera-upload/ \
	  /svc/mnt/prism/import/camera-upload

	mkdir -p /svc/mnt/prism/import/sd-staging
	sudo bindfs -u 1000 --create-for-user=100 --create-for-group=101 /share/hhartmann/garage/SD-Staging/ \
	  /svc/mnt/prism/import/sd-staging

umount:
	-sudo umount /svc/mnt/prism/pictures/attic
	-sudo umount /svc/mnt/prism/pictures
	-sudo umount /svc/mnt/prism/import/*


test:
	source /svc/lib/include.sh && check_url prism.heinrichhartmann.net
