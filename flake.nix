{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... }: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, pkgs, ... }:
            let
              overlay-unstable = final: prev: {
                unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
              };
            in
            {
              nixpkgs.overlays = [ overlay-unstable ];

              #nix = {
              #    binaryCachePublicKeys = ["nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="];
              #    binaryCaches = ["https://nixpkgs-wayland.cachix.org"];
              #};

              imports =
                [
                  ./hardware-configuration.nix
                  ./configuration.nix
                ];
            }
          )
        ];
      };
    };
  };
}
