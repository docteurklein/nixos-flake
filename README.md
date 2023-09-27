# install

1. `nix build .#liveusb`
2. `sudo dd status=progress if=./result/iso/nixos-23.05.20230327.4bb072f-x86_64-linux.isonixos.iso of=/dev/sdc bs=4096 oflag=direct,sync`
3. boot on it on remote machine
4. `nix build .#nixosConfigurations.florian-laptop.config.system.build.diskoScript`
5. `echo -n "$DISK_PASSWORD" | ssh root@192.168.1.14 -T "cat > /tmp/secret.key"`
6. `nix run --inputs-from . github:numtide/nixos-anywhere -- root@192.168.1.14 --flake github:docteurklein/nixos-flake#florian-laptop`


## later reconfig

    nix run .#apps.nixinate.florian-laptop

## home-manager on non-nixos

    nix run home-manager/release-23.05 -- switch --flake .
