#!/bin/bash
mount /dev/sda4 /mnt
mount --mkdir /dev/sda1 /mnt/boot
mount --mkdir /dev/sda5 /mnt/var
mount --mkdir /dev/sda6 /mnt/home
swapon /dev/sda3
arch-chroot /mnt nmcli device wifi connect \047"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f" | sed s/.psk//)"\047 password "$(cat /var/lib/iwd/"$(sudo find /var/lib/iwd -type f -name "*.psk" -printf "%f")" | grep --color=never Passphrase= | sed s/Passphrase=//)"