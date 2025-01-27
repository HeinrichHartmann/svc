{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in
      {
        devShells.default = pkgs.mkShell { packages = [
          pkgs.coreutils
          pkgs.util-linux # umount
          pkgs.gnumake
          pkgs.bindfs
          pkgs.git
          pkgs.opentofu
          pkgs.terraform
        ]; };
      }
    );
}
