URL=
include /svc/lib/include.mk

build:
	docker build --tag docker.heinrichhartmann.net/restic .
	docker push docker.heinrichhartmann.net/restic

# stats:
# 	docker run -v $$(pwd):/restic -it docker.heinrichhartmann.net/restic \
# 	  bash -c 'cd /restic; source auth.sh.crypt; restic --cache-dir=./cache --host pve --repo b2:hh-restic-b2 snapshots'
#
# mount:
# 	mkdir -p mount
# 	nix-shell -p restic --command 'restic --cache-dir=./cache --host pve --repo b2:hh-restic-b2 mount ./mount'
#
# info:
# 	nix-shell -p backblaze-b2 --command 'backblaze-b2 get-bucket --showSize hh-restic-b2'
