{
  description = "PVE Server Configuration";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11"; };
  outputs = { self, nixpkgs, ... }:
    let lib = nixpkgs.lib;
    in {
      nixosConfigurations.pve = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/tailscale.nix
          ./modules/svc-services.nix
          ./modules/zfs-configuration.nix
          ./modules/monitoring.nix
        ];
      };
    };
}
