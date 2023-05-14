#!/bin/bash
#mount /dev/sda4 /mnt
#mount --mkdir /dev/sda1 /mnt/boot
#mount --mkdir /dev/sda5 /mnt/var
#mount --mkdir /dev/sda6 /mnt/home
#swapon /dev/sda3
echo -e '#!/bin/bash
nmcli device wifi connect \047'"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f" | sed s/.psk//)"'\047 password \047'$(grep Passphrase= /var/lib/iwd/$(find /var/lib/iwd -type f -name "*.psk" -printf "%f") | sed s/Passphrase=//)'\047' > /mnt/home/stardestart/archinstall.sh
