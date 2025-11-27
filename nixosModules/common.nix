{ inputs, config, pkgs, lib, ... }: {
  imports = [
    inputs.nix-snapshotter.nixosModules.default
    inputs.niri.nixosModules.niri
  ];

  options = with lib.types; {
    resources = lib.mkOption {
      type = submodule {
        options = {
          ram = lib.mkOption {
            type = int;
          };
          disk = lib.mkOption {
            type = str;
          };
        };
      };
    };
  };

  config = {

    home-manager.sharedModules = [ inputs.agenix.homeManagerModules.default ];

    age.secrets.proton-auth-user-pass.file = ../secrets/proton-auth-user-pass;
    age.secrets.proton-ca.file = ../secrets/proton-ca;
    age.secrets.proton-tls-crypt.file = ../secrets/proton-tls-crypt;

    disko.devices = {
      disk.${config.resources.disk} = {
        type = "disk";
        device = config.resources.disk;
        content = {
          type = "gpt";
          efiGptPartitionFirst = false;
          # preCreateHook = "sleep 3";
          partitions = {
            boot = {
              priority = 1;
              type = "EF00";
              size = "32M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = null;
              };
              hybrid = {
                mbrPartitionType = "0x0c";
                mbrBootableFlag = false;
              };
            };
            ESP = {
              label = "boot";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            # root = {
            #   size = "100%";
            #   content = {
            #     type = "filesystem";
            #     format = "ext4";
            #     mountpoint = "/";
            #   };
            # };
            luks = {
              label = "luks";
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [ ];
                settings = {
                  allowDiscards = true;
                  fallbackToPassword = true;
                };
                passwordFile = "/tmp/secret.key";
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
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

    boot = {
      # readOnlyNixStore = false;
      kernelParams = [ "boot.shell_on_fail" ]; 
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      extraModulePackages = [ ];
      kernelModules = [ "dm-snapshot" ];
      initrd.kernelModules = [ "dm-snapshot" ];
      initrd.availableKernelModules = [ ];
    };

    systemd.settings.Manager = {
      # DefaultTimeoutStartSec = 20;
      DefaultTimeoutStopSec = 20;
    };

    services.resolved.enable = true;

    services.fwupd.enable = true;

    services.openvpn.servers = {
      proton = {
        config = ''
          client
          dev tun
          proto udp

          remote 185.177.124.84 4569
          remote 185.177.124.84 80
          remote 185.177.124.84 1194
          remote 185.177.124.84 51820
          remote 185.177.124.84 5060

          remote-random
          resolv-retry infinite
          nobind

          cipher AES-256-GCM

          setenv CLIENT_CERT 0
          tun-mtu 1500
          mssfix 0
          persist-key
          persist-tun

          reneg-sec 0

          remote-cert-tls server
          auth-user-pass

          script-security 2

          ca ${config.age.secrets.proton-ca.path}
          tls-crypt ${config.age.secrets.proton-tls-crypt.path}
        '';
        authUserPass = config.age.secrets.proton-auth-user-pass.path;
        updateResolvConf = true;
        autoStart = false;
      };
    };

    networking = {
      # nameservers = [ "1.1.1.1" "8.8.8.8" ];
      useDHCP = true;
      enableIPv6 = true;
      firewall = {
        checkReversePath = false;
        trustedInterfaces = [ "docker0" ];
        enable = true;
        allowedTCPPorts = [ 80 443 22 8080 8081 6443 3000 ];
        allowedUDPPorts = [ 53 ];
        allowPing = true;
      };
    };

    time.timeZone = "Europe/Paris";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = ["en_US.UTF-8/UTF-8" "fr_FR.UTF-8/UTF-8"];
      extraLocaleSettings = {
        LC_MESSAGES = "fr_FR.UTF-8";
      };
    };

    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
      packages = with pkgs; [ terminus_font ];
    };

    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      packages = with pkgs; [
        powerline-fonts
        powerline-symbols
        font-awesome
      ];
    };

    services = {
      # ollama = {
      #   enable = true;
      #   acceleration = "cuda";
      # };
      logrotate = {
        enable = true;
      };
      journald.extraConfig = ''
        MaxRetentionSec=7day
        RateLimitInterval=10s
        RateLimitBurst=100000
      '';
      openssh = {
        enable = true;
        settings = {
          X11Forwarding = false;
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        ports = [ 22 ];
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
      postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
        extensions = with pkgs.postgresql18Packages; [
          wal2json
          pg_ivm
          pg_hint_plan
        ];
        settings = let
          ram = config.resources.ram * 0.75; ## @TODO use config.systemd.services.postgresql.serviceConfig.MemoryMax
        in rec {
          log_connections = true;
          log_statement = "all";
          logging_collector = true;
          log_disconnections = true;
          log_destination = lib.mkForce "syslog";
          log_temp_files = 0;
          wal_level = "logical";
          #"auto_explain.log_nested_statements" = true;
          #"auto_explain.log_min_duration" = 0;
          shared_preload_libraries = "auto_explain,pg_hint_plan,pg_stat_statements";
          max_connections = 100;
          # shared_buffers = "${toString (builtins.ceil (ram / 4) / 1000 / 1000)} GB"; # 1/4th of RAM
          # work_mem =  builtins.ceil ((ram / max_connections) / 4); # 1/4th of RAM / max_connections
          # # effective_cache_size = builtins.ceil(ram * 0.75); # 75% of total RAM
          # effective_cache_size = "${toString (builtins.ceil (ram * 0.75) / 1000 / 1000)} GB"; # 1/4th of RAM
          maintenance_work_mem = "1GB";
          checkpoint_completion_target = 0.9;
          wal_buffers = "16MB";
          default_statistics_target = 100;
          random_page_cost = 1.1;
          effective_io_concurrency = 200;
          min_wal_size = "1GB";
          max_wal_size = "4GB";
          max_worker_processes = 6;
          max_parallel_workers_per_gather = 3;
          max_parallel_workers = 6;
          max_parallel_maintenance_workers = 3;
        };
      };
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.niri}/bin/niri-session";
          user = "florian";
        };
      };
    };

    services.nix-snapshotter = {
      enable = true;
      # setContainerdSnapshotter = true;
    };

    systemd.services.postgresql.serviceConfig = {
      # MemoryMax = builtins.ceil (config.resources.ram * 0.75);
    };

    virtualisation = {
      vmVariantWithDisko = {
        # virtualisation.fileSystems."/persist".neededForBoot = true;
        # virtualisation.fileSystems."/".encrypted.keyFile = "/tmp/secret.key";
      };
      containerd.enable = true;
      docker = {
        enable = true;
        #package = pkgs.unstable.docker;
        autoPrune.enable = true;
        enableOnBoot = true;
      };
    };

    security = {
      rtkit.enable = true;
      polkit.enable = true;
      sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };
      wrappers.wshowkeys = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.wshowkeys}/bin/wshowkeys";
      };
    };

    users = {
      mutableUsers = false;
      users.florian = {
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" ];
        shell = pkgs.fish;
        uid = 1000;
        # mkpasswd -m sha-512 password
        hashedPassword = "$6$Qxe1C3WtH06$Tl9DzDcMqtuhASktIm.raH/cICBkcquiBYhB./ZhmC6S6IeBmT3uhIBX6dNNXa46GQJDt9hhHF1sCy25fAnfD.";
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNFd+owyL4UYCZM9PqJnl2Z6SMeBQQmZdi09tXCTgzLxWL1LnLyB45GoDLSt9PWkcy8+Dhk3SU1JRI32rwXdpPSCGXYETLvrxGKyZ7ySxl+tdVcdOawOvb5MC3+258SDK8b2Fz0pDCZAUl8NYyDv27efO4m2JH27DWoCOMk3DezAk+itLzNeRh61LJd/9+H7ZvqyXDjSdS12GlfVGs4MFAALq5zZXX76dh4Xs21XC6IwZK7Dq8NE0WARJT8OL8IT+tTcs0qoQDNBd+eb4Llxe7pRcnM/Pd9Wo0ceKGdjfIiOKRaFN6Q7WzI+l+fVdHa4vFHQVxOOydmD2F0jVIzXoT florian@florian"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYjyOT9I0Tpr72BeMjQbq7aP0Pj+octMDI5yDnn/BKy"
        ];
        packages = with pkgs; [
        ];
      };
    };
    documentation = {
      man.enable = false;
    };
    programs = {
      niri.enable = true;
      steam.enable = true;
      ssh.startAgent = false;
      fish.enable = true;
    };
    programs.dconf.enable = true;

    environment = {
      sessionVariables = {
      };
      variables = {
        EDITOR = "hx";
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        LESS = "-SRXFi";
        NIXPKGS_ALLOW_UNFREE = "1";
      };
      pathsToLink = [
        "/libexec"
      ];
      systemPackages = with pkgs; [
        inputs.agenix.packages.${stdenv.hostPlatform.system}.default
        update-systemd-resolved
        wl-clipboard
        xwayland-satellite
        grim
        ripgrep
        slurp
        wireplumber
        nerdctl
        man
        nautilus
        iftop
        jq
        htop
        git
        inotify-tools
        binutils
        gnutls
        gnumake
        # stremio
        alacritty
        docker-compose
        gcc
        wget
        curl
        bind
        mkpasswd
        cachix
        tmux
        dmidecode
        fd
        ripgrep
        socat
        xdot
        graphviz
        libclang.lib
        pavucontrol
        pulseaudio-ctl
        vlc
        nil
      ];
    };

    nixpkgs = {
      overlays = [
        (self: super: {
        })
        inputs.nix-snapshotter.overlays.default 
        inputs.nur.overlays.default
        inputs.niri.overlays.niri
      ];
      config = {
        allowBroken = true;
        allowUnfree = true;
        packageOverrides = pkgs: with pkgs; {
        };
        permittedInsecurePackages = [
          # "qtwebengine-5.15.19"
        ];
      };
    };

    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        max-jobs = lib.mkDefault 8;
        sandbox = false;
        trusted-users = [ "@wheel" ];
        allowed-users = [ "@wheel" ];
        auto-optimise-store = true;
        allow-import-from-derivation = true;
        accept-flake-config = true;
        system-features = [ "recursive-nix" ];
      };
      extraOptions = ''
        experimental-features = nix-command flakes impure-derivations ca-derivations recursive-nix
        keep-outputs = true
        keep-derivations = true
      '';
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d"; # or +5
      };
      optimise = {
        automatic = true;
        dates = [ "weekly" ];
      };
    };

    system = {
      stateVersion = "22.11"; # keep to lowest possible to prove BC
      autoUpgrade = {
        enable = true;
        allowReboot = false;
        flake = inputs.self.outPath;
        flags = [
          "--recreate-lock-file"
          "-L" # print build logs
        ];
        dates = "weekly";
      };
    };
  };
}
