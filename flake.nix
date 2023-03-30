{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # helix.url = "github:helix-editor/helix";
    # pgx.url = "github:tcdi/pgx";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixinate = {
    #   url = "github:matthewcroughan/nixinate";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, nixos-generators, disko, nixinate, ... }@attrs: {
    # apps = nixinate.nixinate.x86_64-linux self;
    nixosConfigurations = {
      "florian-desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ({ config, pkgs, ... }: {
            imports = [
              ./configuration.nix
            ];
            networking.hostName = "florian-desktop";
            console.keyMap = "fr-bepo";
            services.xserver.xkbVariant = "bepo";
            services.xserver.videoDrivers = [ "nvidia" ];
            hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
            services.xserver.layout = "fr";
            fileSystems."/" = {
              device = "/dev/disk/by-label/root";
              fsType = "ext4";
              options = [ "noatime" "nodiratime" ]; 
            };

            fileSystems."/boot" = {
              device = "/dev/disk/by-partlabel/boot";
              fsType = "ext2";
            };

            swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

            boot.loader.grub.device = "/dev/sdb";
            boot.initrd.luks.devices = {
              crypt = {
                device = "/dev/sdb2";
                preLVM = true;
              };
            };
          })
        ];
      };
      "florian-laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          disko.nixosModules.disko
          ({ config, pkgs, modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              ./configuration.nix
            ];

            nix.registry = {
              nixpkgs.flake = nixpkgs;
            };
            networking.hostName = "florian-laptop";
            console.keyMap = "fr";
            services.xserver.layout = "fr";
            boot.loader.grub.device = "/dev/sda";
            disko.devices.disk.sda = {
              type = "disk";
              device = "/dev/sda";
              content = {
                type = "table";
                format = "gpt";
                partitions = [
                  {
                    name = "boot";
                    type = "partition";
                    start = "0";
                    end = "1M";
                    flags = [ "bios_grub" ];
                  }
                  {
                    type = "partition";
                    name = "ESP";
                    start = "1M";
                    end = "512M";
                    bootable = true;
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                    };
                  }
                  {
                    type = "partition";
                    name = "root";
                    start = "512M";
                    end = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/";
                    };
                  }
                ];
              };
            };
          })
          # {
          #   _module.args.nixinate = {
          #     host = "192.168.1.14";
          #     sshUser = "root";
          #     buildOn = "local"; # valid args are "local" or "remote"
          #     substituteOnTarget = false; # if buildOn is "local" then it will substitute on the target, "-s"
          #     hermetic = false;
          #   };
          # }
        ];
      };
    };
    packages.x86_64-linux = {
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
}
