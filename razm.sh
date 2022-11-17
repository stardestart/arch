#!/bin/bash
loadkeys ru
setfont ter-v18n
time="$(curl https://ipapi.co/timezone)"
timedatectl set-timezone $time
lsblk -d
echo "
"
read -p "Введите метку диска на который будет установлена ОС: " disk
echo "
"
swapoff -a
umount /dev/{disk}
boot="$(efibootmgr | grep Boot)"
if [ -z "$boot" ];
then
fdisk /dev/$disk <<EEOF
g
n
1
2048
+512m
n
2
""
+1m
t
2
4
n
3
""
+1g
n
4
""
""
w
EEOF
mkfs.ext2 /dev/${disk}1 -L boot <<EEOF
y
EEOF
mkswap /dev/${disk}3 -L swap
mkfs.ext4 /dev/${disk}4 -L root <<EEOF
y
EEOF
mount /dev/${disk}4 /mnt
mount --mkdir /dev/${disk}1 /mnt/boot
else
fdisk /dev/$disk <<EEOF
g
n
1
2048
+512m
t
1
n
2
""
+1g
n
3
""
""
w
EEOF
mkfs.fat -F32 /dev/${disk}1 -n boot <<EEOF
y
EEOF
mkswap /dev/${disk}2 -L swap
mkfs.ext4 /dev/${disk}3 -L root <<EEOF
y
EEOF
mount /dev/${disk}3 /mnt
mount --mkdir /dev/${disk}1 /mnt/boot
fi
