{ config, inputs, pkgs, ... }: {
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
  networking.hostName = "dell-xps-13";
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;

  age.secrets.wireless.file = ../secrets/wireless.age;
  networking.wireless.secretsFile = config.age.secrets.wireless.path;
  networking.wireless.networks = {
    "Livebox-9500" = {
      psk = "ext:PSK_LIVEBOX_9500";
    };
  };
  
  console.keyMap = "fr";
  services.xserver.xkb.layout = "fr";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "intel" ];
  nixpkgs.config.packageOverrides = pkgs: {
    # vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.kernelModules = [ "kvm-intel" ];

  resources = {
    ram = 8 * 1000 * 1000 * 1000;
    disk = "/dev/nvme0n1";
  };
}
