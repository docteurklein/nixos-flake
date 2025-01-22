{ config, inputs, ... }: {
  imports = [
    ./common.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.florian = import ../homeModules/default.nix;
  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
    self.flake = inputs.self;
  };
  networking.hostName = "florian-desktop";
  console.keyMap = "fr-bepo";
  services.xserver.xkb.layout = "fr";
  services.xserver.xkb.variant = "bepo";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.pulseaudio.support32Bit = config.hardware.pulseaudio.enable;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];

  resources = {
    ram = 16 * 1000 * 1000 * 1000;
    disk = "/dev/nvme0n1";
  };
}
