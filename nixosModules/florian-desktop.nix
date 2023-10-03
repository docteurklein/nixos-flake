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
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];

  disk = "/dev/nvme0n1";
}
