{
  description = "Python project with 'hello' package using Nix flakes";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09"; };

  outputs = { self, nixpkgs, ... }: {

    # Define the Flake's package set
    packages = import nixpkgs { system = "x86_64-linux"; };

    # Build a development environment with the 'hello' package
    devShell = {
      x86_64-linux =
        self.packages.mkShell { buildInputs = [ self.packages.poetry ]; };
    };
  };
}
