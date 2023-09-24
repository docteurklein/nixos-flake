{ config, inputs, ... }: {
  imports = [
    ./common.nix
  ];
  # nixpkgs.overlays = [ overlay-unstable ];
  nixpkgs.config.allowUnfree = true;
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    self.flake = inputs.self;
  };
  networking.hostName = "florian-desktop";
  console.keyMap = "fr-bepo";
  services.xserver.layout = "fr";
  services.xserver.xkbVariant = "bepo";
  services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.nvidia.package = pkgs.linuxKernel.packages.linux_6_1.nvidia_x11;
  #hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

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
}
