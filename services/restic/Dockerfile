FROM nixos/nix

# https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=restic
RUN nix-env -i restic-0.9.6 -f https://github.com/NixOS/nixpkgs-channels/archive/1975b8687474764c157e6a220fdcad2c5dc348a1.tar.gz

RUN nix-env -i bash-5.0-p18 -f https://github.com/NixOS/nixpkgs/archive/046f8835dcb9082beb75bb471c28c832e1b067b6.tar.gz

# for date(1) util
RUN nix-env -i coreutils-8.32 -f https://github.com/NixOS/nixpkgs/archive/bed08131cd29a85f19716d9351940bdc34834492.tar.gz
