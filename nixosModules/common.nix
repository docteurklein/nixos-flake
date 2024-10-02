{ inputs, config, pkgs, lib, ... }: {

  imports = [
    inputs.nix-snapshotter.nixosModules.default
    inputs.niri.nixosModules.niri
  ];

  options = {
    disk = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    disko.devices = {
      disk.${config.disk} = {
        type = "disk";
        device = config.disk;
        content = {
          type = "gpt";
          partitions = {
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
      readOnlyNixStore = false;
      kernelParams = [ "boot.shell_on_fail" ]; 
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # grub = {
        #   enable = true;
        #   configurationLimit = 10;
        #   enableCryptodisk = true;
        #   device = config.disk;
        #   # efiSupport = true;
        #   # efiInstallAsRemovable = true;
        # };
      };
      extraModulePackages = [ ];
      kernelModules = [ "dm-snapshot" ];
      initrd.kernelModules = [ "dm-snapshot" ];
      initrd.availableKernelModules = [ ];
    };

    systemd.extraConfig = ''
      DefaultTimeoutStopSec=20s
      DefaultTimeoutStartSec=20s
    '';

    services.resolved.enable = true;
    # services.openvpn.servers = {
    #   homeVPN = {
    #     config = "config /home/florian/proton.ovpn";
    #     updateResolvConf = true;
    #   };
    # };

    networking = {
      # nameservers = [ "1.1.1.1" "8.8.8.8" ];
      useDHCP = true;
      enableIPv6 = true;
      firewall = {
        trustedInterfaces = [ "docker0" ];
        enable = true;
        allowedTCPPorts = [ 80 443 22 8080 8081 6443 ];
        allowedUDPPorts = [ 53 ];
        allowPing = true;
      };
    };

    time.timeZone = "Europe/Paris";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" ];
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
      tempo = {
        enable = true;
        configFile = ../tempo.yaml;
      };
      grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            domain = "localhost";
            protocol = "http";
            # cert_key = "/etc/nixos/dck-home.freeddns.org-key.pem";
            # cert_file = "/etc/nixos/dck-home.freeddns.org.pem";
          };
        };
        provision.datasources.settings = {
          apiVersion = 1;

          datasources = [{
            name = "Pyroscope";
            type = "pyroscope";
            url = "http://127.0.0.1:4040";
          }];
        };
      };
      prometheus = {
        enable = true;
        port = 9001;
        exporters = {
          node = {
            enable = true;
            port = 9002;
          };
        };
        scrapeConfigs = [
          {
            job_name = "nixos";
            static_configs = [{
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            }];
          }
          {
            job_name = "tempo";
            static_configs = [{
              targets = [ "127.0.0.1:3200" ];
            }];
          }
          {
            job_name = "pyroscope";
            static_configs = [{
              targets = [ "127.0.0.1:4040" ];
            }];
          }
        ];
      };
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
          X11Forwarding = true;
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
        package = pkgs.postgresql_15;
        extraPlugins = with pkgs.postgresql15Packages; [
          wal2json
          pg_ivm
          pg_hint_plan
        ];
        settings = {
          log_connections = true;
          log_statement = "all";
          logging_collector = true;
          log_disconnections = true;
          log_destination = lib.mkForce "syslog";
          wal_level = "logical";
          #"auto_explain.log_nested_statements" = true;
          #"auto_explain.log_min_duration" = 0;
          shared_preload_libraries = "auto_explain,pg_hint_plan,pg_stat_statements";
          max_connections = 100;
          shared_buffers = "3GB"; # 1/4th of RAM
          work_mem = "30MB"; # 1/4th of RAM / max_connections
          effective_cache_size = "9GB"; # 75% of total RAM
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

    environment.sessionVariables = {
      KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
    };
    # networking.extraHosts = "127.0.0.1 api.kube";

    services.kubernetes = {
      roles = ["master" "node"];
      masterAddress = "localhost";
      apiserverAddress = "https://localhost:6443";
      apiserver = {
        advertiseAddress = "127.0.0.1";
        securePort = 6443;
        allowPrivileged = true;
      };
      addons.dns = {
        enable = true;
        corefile = ''
          .:10053 {
            log
            errors
            health :10054
            kubernetes ${config.services.kubernetes.addons.dns.clusterDomain} in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :10055
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
          }
        '';
      };
      kubelet.extraOpts = "--image-service-endpoint unix:///run/nix-snapshotter/nix-snapshotter.sock --fail-swap-on=false";
    };

    # services.k3s = {
    #   enable = true;
    #   package = pkgs.k3s;
    #   extraFlags = "--write-kubeconfig /etc/rancher/k3s/k3s.yaml --write-kubeconfig-mode 644 --image-service-endpoint unix:///run/nix-snapshotter/nix-snapshotter.sock";
    # };

    
    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command = "${pkgs.niri}/bin/niri --session";
          user = "florian";
        };
      };
    };

    services.nix-snapshotter = {
      enable = true;
      # setContainerdSnapshotter = true;
    };

    systemd.services.postgresql.serviceConfig = {
      MemoryMax = "12G";
    };

    virtualisation = {
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

    systemd.timers."wallpaper" = {
      wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          Unit = "wallpaper.service";
        };
    };

    environment = {
      variables = {
        EDITOR = "hx";
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        LESS = "-SRXFi";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
      pathsToLink = [
        "/libexec"
      ];
      systemPackages = with pkgs; [
        xwayland-satellite
        grim
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
        firefox
        stremio
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
        ((vim_configurable.override { }).customize {
          name = "vim";
          vimrcConfig = {
            customRC = builtins.readFile ../dotfiles/vimrc;
          };
          vimrcConfig.packages.myVimPackage = with vimPlugins; {
            start = [
              jellybeans-vim
              vim-airline
              fugitive
              ctrlp-vim
              tabular
              vim-surround
              vim-lsp
              fzf-vim
            ];
          };
        })
        fd
        ripgrep
        socat
        (google-cloud-sdk.withExtraComponents ([google-cloud-sdk.components.gke-gcloud-auth-plugin]))
        kubectl
        kubectx
        kubernetes-helm
        k9s
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
        inputs.nur.overlay
      ];
      config = {
        allowBroken = true;
        allowUnfree = true;
        packageOverrides = pkgs: with pkgs; {
        };
      };
    };

    nix = {
      settings = {
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      package = pkgs.nixFlakes;

      settings = {
        max-jobs = lib.mkDefault 8;
        sandbox = true;
        trusted-users = [ "@wheel" ];
        allowed-users = [ "@wheel" ];
        auto-optimise-store = true;
        allow-import-from-derivation = true;
      };
      extraOptions = ''
        experimental-features = nix-command flakes repl-flake
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
        flake = "/etc/nixos";
        flags = [
          "--recreate-lock-file"
          "-L" # print build logs
        ];
        dates = "weekly";
      };
    };
  };
}
