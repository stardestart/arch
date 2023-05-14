#!/bin/bash
#mount /dev/sda4 /mnt
#mount --mkdir /dev/sda1 /mnt/boot
#mount --mkdir /dev/sda5 /mnt/var
#mount --mkdir /dev/sda6 /mnt/home
#swapon /dev/sda3
echo -e '#!/bin/bash
nmcli device wifi connect "'"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f" | sed s/.psk//)"'" password "'"$(grep Passphrase= /var/lib/iwd/"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f")" | sed s/Passphrase=//)"'"' > /mnt/home/stardestart/archinstall.sh
