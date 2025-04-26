SHELL = /bin/bash
NIXCMD = nixos-rebuild --flake .

@PHONY: switch
switch:
	$(NIXCMD) switch

@PHONY: rebuild
rebuild:
	$(NIXCMD) build

@PHONY: diff
diff:
	echo "# List"
	-diff -Naurq /run/current-system ./result
	read
	echo "# Diff"
	-diff -Naur /run/current-system ./result

help:
	cat Makefile
