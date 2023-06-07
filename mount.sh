#!/bin/bash
mount /dev/sda4 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
mount --mkdir /dev/sda5 /mnt/var
mount --mkdir /dev/sda6 /mnt/home
swapon /dev/sda3
arch-chroot /mnt bootctl install
