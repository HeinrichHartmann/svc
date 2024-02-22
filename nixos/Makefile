SHELL = /bin/bash

switch:
	nixos-rebuild switch --flake .

build:
	nixos-rebuild build  --flake .

diff:
	echo "# List"
	-diff -Naurq /run/current-system ./result
	echo "# Diff"
	-diff -Naur /run/current-system ./result

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
