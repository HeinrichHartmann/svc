{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # pkgs = nixpkgs.legacyPackages.${system};
        # pkgs = import nixpkgs { system="x86_64-linux"; config.allowUnfree = true; };
        pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
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
