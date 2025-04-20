SHELL = /bin/bash

@PHONY: switch
switch:
	sudo nixos-rebuild switch --flake .

@PHONY: rebuild
rebuild:
	nixos-rebuild build  --flake .

@PHONY: diff
diff:
	echo "# List"
	-diff -Naurq /run/current-system ./result
	read
	echo "# Diff"
	-diff -Naur /run/current-system ./result

help:
	cat Makefile
