.PHONY: certs
certs:
	mkdir -p log work config
	-poetry install
	AWS_SHARED_CREDENTIALS_FILE=./aws-credentials.crypt \
	AWS_CONFIG_FILE=./aws-config.crypt \
	  ./certbot.sh certonly --dns-route53 --force-renew \
	  --agree-tos --email 'derhein@gmail.com' --no-eff-email \
	  -d '*.heinrichhartmann.net' \
	  -d '*.lan.heinrichhartmann.net' \
	  -d '*.ts.heinrichhartmann.net'

help:
	./certbot.sh -h all

list:
	./certbot.sh certificates

renew:
	./certbot.sh renew

show:
	find ./config/live -name 'cert.pem' -exec bash -c 'printf "# {}\n" ; openssl x509 -text -in {}' \;

.PHONY: clean
clean:
	-rm -rf log work  # removes temp files
