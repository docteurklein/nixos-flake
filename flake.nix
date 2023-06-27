{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixos-hardware, nixos-generators, agenix, disko, nixinate, ... }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in {
    apps = nixinate.nixinate.x86_64-linux self;
    nixosConfigurations = {
      "florian-desktop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          ({ config, pkgs, ... }: {
            nixpkgs.overlays = [ overlay-unstable ];
            nix.registry = {
              nixpkgs.flake = nixpkgs;
              self.flake = inputs.self;
            };
            imports = [
              ./configuration.nix
            ];
            networking.hostName = "florian-desktop";
            console.keyMap = "fr-bepo";
            services.xserver.layout = "fr";
            services.xserver.xkbVariant = "bepo";
            services.xserver.videoDrivers = [ "nvidia" ];
            #hardware.nvidia.package = pkgs.linuxKernel.packages.linux_6_1.nvidia_x11;
            hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
            #boot.kernelPackages = pkgs.linuxPackages_latest;

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

            boot.loader.grub = {
              device = "/dev/sdb";
              efiSupport = false;
              efiInstallAsRemovable = false;
            };
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
        specialArgs = inputs;
        modules = [
          ({ config, pkgs, modulesPath, ... }: {
            nixpkgs.overlays = [ overlay-unstable ];
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              agenix.nixosModules.default
              ./configuration.nix
            ];

            nix.registry = {
              nixpkgs.flake = nixpkgs;
              self.flake = inputs.self;
            };
            environment.systemPackages = [ pkgs.unstable.yewtube ];
            networking.hostName = "florian-laptop";
            networking.wireless.enable = true;
            networking.wireless.userControlled.enable = true;
            age.secrets.wireless.file = ./secrets/wireless.age;
            networking.wireless.environmentFile = config.age.secrets.wireless.path;
            networking.wireless.networks = {
              "Livebox-9500" = {
                pskRaw = "@PSK_LIVEBOX_9500@";
              };
            };
            console.keyMap = "fr";
            services.xserver.layout = "fr";
            services.xserver.libinput = { enable = true; };
            services.xserver.videoDrivers = [ "intel" ];

            nixpkgs.config.packageOverrides = pkgs: {
              vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
            };
            hardware.opengl = {
              enable = true;
              extraPackages = with pkgs; [
                intel-media-driver # LIBVA_DRIVER_NAME=iHD
                vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
                vaapiVdpau
                libvdpau-va-gl
              ];
            };

            boot.loader.grub = {
              device = "/dev/sda";
              efiSupport = true;
              efiInstallAsRemovable = true;
            };
            disko.devices.disk.sda = {
              type = "disk";
              device = "/dev/sda";
              content = {
                type = "table";
                format = "gpt";
                partitions = [
                  {
                    name = "boot";
                    start = "0";
                    end = "1M";
                    flags = [ "bios_grub" ];
                  }
                  {
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
          {
            _module.args.nixinate = {
              host = "192.168.1.15";
              sshUser = "florian";
              buildOn = "local"; # valid args are "local" or "remote"
              substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
              hermetic = false;
            };
          }
        ];
      };
      "dell-xps-13" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs;
        modules = [
          ({ config, pkgs, modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              agenix.nixosModules.default
              nixos-hardware.nixosModules.dell-xps-13-9310
              ./configuration.nix
            ];

            nix.registry = {
              nixpkgs.flake = nixpkgs;
              self.flake = inputs.self;
            };
            environment.systemPackages = [ pkgs.unstable.fusionInventory ];
            networking.hostName = "dell-xps-13";
            networking.wireless.enable = true;
            networking.wireless.userControlled.enable = true;
            age.secrets.wireless.file = ./secrets/wireless.age;
            networking.wireless.environmentFile = config.age.secrets.wireless.path;
            networking.wireless.networks = {
              "Livebox-9500" = {
                pskRaw = "@PSK_LIVEBOX_9500@";
              };
            };
            hardware.bluetooth.enable = true;
            console.keyMap = "fr";
            services.xserver.layout = "fr";
            services.xserver.libinput = { enable = true; };
            services.xserver.videoDrivers = [ "intel" ];

            nixpkgs.config.packageOverrides = pkgs: {
              vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
            };
            hardware.opengl = {
              enable = true;
              extraPackages = with pkgs; [
                intel-media-driver
                vaapiIntel
                vaapiVdpau
                libvdpau-va-gl
              ];
            };

            sound.mediaKeys.enable = true;

            boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
            boot.kernelModules = [ "kvm-intel" ];

            boot.loader.grub = {
              device = "/dev/nvme0n1";
              efiSupport = true;
              efiInstallAsRemovable = true;
            };
            disko.devices = {
              disk.nvme0n1 = {
                type = "disk";
                device = "/dev/nvme0n1";
                content = {
                  type = "table";
                  format = "gpt";
                  partitions = [
                    {
                      name = "boot";
                      start = "0";
                      end = "1M";
                      flags = [ "bios_grub" ];
                    }
                    {
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
                      name = "root";
                      start = "512M";
                      end = "100%";
                      content = {
                        type = "luks";
                        name = "crypted";
                        extraOpenArgs = [ "--allow-discards" ];
                        settings.keyFile = "/tmp/secret.key";
                        content = {
                          type = "lvm_pv";
                          vg = "pool";
                        };
                      };
                    }
                  ];
                };
              };
              lvm_vg = {
                pool = {
                  type = "lvm_vg";
                  lvs = {
                    root = {
                      size = "100%FREE";
                      content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                        mountOptions = [
                          "defaults"
                          "noatime"
                          "nodiratime"
                        ];
                      };
                    };
                  };
                };
              };
            };
          })
          {
            _module.args.nixinate = {
              host = "192.168.1.10";
              sshUser = "florian";
              buildOn = "remote"; # valid args are "local" or "remote"
              substituteOnTarget = true; # if buildOn is "local" then it will substitute on the target, "-s"
              hermetic = false;
            };
          }
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
