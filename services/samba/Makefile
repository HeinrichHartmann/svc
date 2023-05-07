start:
	docker-compose -f docker-compose.yaml.crypt up -d

stop:
	docker-compose -f docker-compose.yaml.crypt down

test:
	@nix-shell -p samba --command 'smbclient -L smb.lan.heinrichhartmann.net -U guest -N -m SMB3 | grep all > /dev/null && echo OK smb.lan.heinrichhartmann.net || echo FAIL smb.lan.heinrichhartmann.net'
