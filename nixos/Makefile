SHELL = /bin/bash
export NIXPKGS_ALLOW_UNFREE = 1

@PHONY: switch
switch:
	nixos-rebuild --impure --flake . switch

@PHONY: rebuild
rebuild:
	nixos-rebuild --impure  --flake . build

@PHONY: diff
diff:
	echo "# List"
	-diff -Naurq /run/current-system ./result
	read
	echo "# Diff"
	-diff -Naur /run/current-system ./result

help:
	cat Makefile
