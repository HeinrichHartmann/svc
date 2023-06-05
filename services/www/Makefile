URL=www.heinrichhartmann.net
include /svc/lib/include.mk

cron:
	echo "<h1>Index</h1><ul>" > /share/hhartmann/attic/www/index.html
	(cd /svc/services; grep -R HostRegexp \
		| sed -n -r 's/^.*[`](.*)[.][{].*$$/\1/p' \
		| grep -v "%" \
		| sort | uniq \
		| sed -r 's|(.*)|<li><a href="https://\1.heinrichhartmann.net/">\1</a></li>|') \
		>> /share/hhartmann/attic/www/index.html
	echo "</ul>" >> /share/hhartmann/attic/www/index.html
