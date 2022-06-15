# personal nix setup

## Prep Disk

```sh
lsblk

export ROOT_DISK=/dev/sdb

wipefs -a $ROOT_DISK
```

## partition disk

```sh

# Create boot partition first
parted -a opt --script "${ROOT_DISK}" \
    mkpart primary ext2 0% 20MiB \
    mkpart primary ext2 20MiB 512MiB \
    mkpart primary 512MiB 100% \
    name 1 grub \
    set 1 bios_grub on \
    name 2 boot \
    name 3 root
    set 3 lvm on \

fdisk $ROOT_DISK -l
```

## Encrypt Primary Disk

```sh
cryptsetup luksFormat /dev/disk/by-partlabel/root

cryptsetup luksOpen /dev/disk/by-partlabel/root root

pvcreate /dev/mapper/root

vgcreate vg /dev/mapper/root

lvcreate -L 4G -n swap vg

lvcreate -l '100%FREE' -n root vg

lvdisplay
```

## Format partitions

```sh
mkfs.ext2 -L boot /dev/disk/by-partlabel/boot

mkfs.ext4 -L root /dev/vg/root

mkswap -L swap /dev/vg/swap

swapon -s
```

## Mount

```sh
mount /dev/disk/by-label/root /mnt

mkdir -p /mnt/boot

mount /dev/disk/by-partlabel/boot /mnt/boot

swapon /dev/vg/swap
```

## Install system

```sh
nix-shell -p git nixFlakes

git clone https://github.com/docteurklein/nixos-flake.git /mnt/etc/nixos

nixos-install --root /mnt --flake /mnt/etc/nixos#default

reboot

sudo nix flake update /etc/nixos/

sudo nixos-rebuild switch --flake /etc/nixos/#default
```
