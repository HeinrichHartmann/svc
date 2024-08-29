.{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = mkShell { packages = [
          pkgs.coreutils
          pkgs.util-linux # umount
          pkgs.bash
          pkgs.gnumake
          pkgs.docker
          pkgs.bindfs
          pkgs.sudo
          pkgs.nix
          pkgs.git
        ]; };
      }
    );
}
