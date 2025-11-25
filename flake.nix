{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-snapshotter = {
      url = "github:pdtpartners/nix-snapshotter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, nixos-generators, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nixosConfigurations/florian-desktop.nix
        ./homeConfigurations/florian.nix
        ./nixosConfigurations/dell-xps-13.nix
      ];
      systems = [ "x86_64-linux" ]; #"x86_64-darwin" ];

      perSystem = {config, pkgs, ...}: {
        packages = {
          liveusb = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            modules = [
              ({config, pkgs, ...}: {
                services.openssh = {
                  enable = true;
                };
                users.extraUsers.root.openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYjyOT9I0Tpr72BeMjQbq7aP0Pj+octMDI5yDnn/BKy"
                ];
              })
            ];
            format = "install-iso";
          };
        };
      };
    };
}
