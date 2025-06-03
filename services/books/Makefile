URL=books.heinrichhartmann.net
include /svc/lib/include.mk

reindex:
	# callibre installs some stuff at startup including the calibredb executable. We need to wait for it to finish...
	docker compose exec calibre bash -c 'cd /books && find . -size +100k -name *.pdf  -print0 | xargs -0 -l25 /usr/bin/calibredb --library-path=/config add'
	docker compose exec calibre bash -c 'cd /books && find . -size +100k -name *.epub -print0 | xargs -0 -l25 /usr/bin/calibredb --library-path=/config add'
	docker compose exec calibre bash -c 'cd /books && find . -size +100k -name *.djvu -print0 | xargs -0 -l25 /usr/bin/calibredb --library-path=/config add'
