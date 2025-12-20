{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils
            util-linux # umount
            gnumake
            bindfs
            git
            opentofu
            awscli2
            ruby
            restic
          ];
        };
      }
    );
}
