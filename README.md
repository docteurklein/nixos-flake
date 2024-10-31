# install

```
nix build .#liveusb
sudo dd status=progress if=./result/iso/nixos-23.05.20230327.4bb072f-x86_64-linux.isonixos.iso of=/dev/sdc bs=4096 oflag=direct,sync
echo -n "$DISK_PASSWORD" | ssh root@192.168.1.14 -T "cat > /tmp/secret.key"
nix run --inputs-from . github:numtide/nixos-anywhere -- root@192.168.1.14 \
    --flake github:docteurklein/nixos-flake#florian-laptop
```

## home-manager on non-nixos

    nix run home-manager/master -- switch --flake .
