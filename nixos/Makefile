SHELL = /bin/bash

update:
	nixos-rebuild switch --flake .

help:
	cat Makefile

install-config:
	sudo install -d -m 755 /etc/nixos/
	sudo install -t /etc/nixos/ -m 644 etc/*

hoist-config:
	sudo cp -r /etc/nixos/*.nix etc/
	sudo chown -R "$$(id -u):$$(id -g)" etc/
	git diff etc

rebuild: install-config
	sudo nixos-rebuild switch
