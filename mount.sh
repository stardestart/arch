#!/bin/bash
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
mount --mkdir /dev/nvme0n1p4 /mnt/var
mount --mkdir /dev/nvme0n1p5 /mnt/home
swapon /dev/nvme0n1p2
arch-chroot /mnt pacman -Sy linux-zen
arch-chroot /mnt mkinitcpio
