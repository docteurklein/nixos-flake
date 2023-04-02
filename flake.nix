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
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-generators, disko, nixinate, ... }@attrs: {
    apps = nixinate.nixinate.x86_64-linux self;
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
            networking.interfaces.enp3s0.useDHCP = true;
            console.keyMap = "fr-bepo";
            services.xserver.layout = "fr";
            services.xserver.xkbVariant = "bepo";
            services.xserver.videoDrivers = [ "nvidia" ];
            hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

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
          ({ config, pkgs, nixpkgs-unstable, modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              ./configuration.nix
            ];

            nix.registry = {
              nixpkgs.flake = nixpkgs;
              # nixpkgs-unstable.flake = nixpkgs-unstable;
            };
            environment.systemPackages = [ nixpkgs-unstable.legacyPackages."x86_64-linux".yewtube ];
            networking.hostName = "florian-laptop";
            networking.interfaces.enp1s0.useDHCP = true;
            networking.interfaces.wlp2s0b1.useDHCP = true;
            networking.wireless.enable = true;
            networking.wireless.userControlled.enable = true;
            networking.wireless.networks = {
              "Livebox-9500" = {
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
                    name = "ESP";
                    type = "partition";
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
                    type = "partition";
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
      "florian-work-laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ({ config, pkgs, nixpkgs-unstable, modulesPath, ... }: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              disko.nixosModules.disko
              ./configuration.nix
            ];

            nix.registry = {
              nixpkgs.flake = nixpkgs;
              # nixpkgs-unstable.flake = nixpkgs-unstable;
            };
            environment.systemPackages = with nixpkgs-unstable.legacyPackages."x86_64-linux"; [
              fusionInventory
            ];
            networking.hostName = "florian-work-laptop";
            #networking.interfaces.enp1s0.useDHCP = true;
            networking.interfaces.wlp58s0.useDHCP = true;
            networking.wireless.enable = true;
            networking.wireless.userControlled.enable = true;
            networking.wireless.networks = {
              "Livebox-9500" = {
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
                intel-media-driver
                vaapiIntel
                vaapiVdpau
                libvdpau-va-gl
              ];
            };

            boot.loader.grub.device = "/dev/nvme0n1";
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
                      type = "partition";
                      start = "0";
                      end = "1M";
                      flags = [ "bios_grub" ];
                    }
                    {
                      name = "ESP";
                      type = "partition";
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
                      type = "partition";
                      start = "512M";
                      end = "100%";
                      content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/";
                      };
                      #content = {
                      #  type = "luks";
                      #  name = "crypted";
                      #  extraOpenArgs = [ "--allow-discards" ];
                      #  keyFile = "/tmp/secret.key";
                      #  content = {
                      #    type = "lvm_pv";
                      #    vg = "pool";
                      #  };
                      #};
                    }
                  ];
                };
              };
              #lvm_vg = {
              #  pool = {
              #    type = "lvm_vg";
              #    lvs = {
              #      root = {
              #        type = "lvm_lv";
              #        size = "100%FREE";
              #        content = {
              #          type = "filesystem";
              #          format = "ext4";
              #          mountpoint = "/";
              #          mountOptions = [
              #            "defaults"
              #            "noatime"
              #            "nodiratime"
              #          ];
              #        };
              #      };
              #    };
              #  };
              #};
            };
          })
          {
            _module.args.nixinate = {
              host = "192.168.1.16";
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
