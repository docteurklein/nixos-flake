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
    usb-phone-lock = {
      url = "github:robcohen/usb-phone-lock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, nixos-generators, usb-phone-lock, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nixosConfigurations/florian-desktop.nix
        ./nixosConfigurations/dell-xps-13.nix
        # ./nixosConfigurations/phone.nix
        ./homeConfigurations/florian.nix
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { config, pkgs, system, ...}: {
        packages = {
          liveusb = nixos-generators.nixosGenerate {
            inherit system;
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
          # phone-disk-images = self.nixosConfigurations.phone.config.mobile.outputs.android.android-fastboot-images;
        };
      };
    };
}
