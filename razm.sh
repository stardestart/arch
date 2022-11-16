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
boot="$(efibootmgr | grep Boot)"
if [ -z "$boot" ];
then
fdisk /dev/$disk <<EOF
g
n
1
2048
+512m
y
n
2
\n
+1m
y
t
2
4
n
3
\n
+1g
n
4
\n
\n
w
EOF
mkfs.ext2 /dev/${disk}1 -L boot<<EOF
y
EOF
mkswap /dev/${disk}3 -L swap
mkfs.ext4 /dev/${disk}4 -L root<<EOF
y
EOF
mount /dev/${disk}4 /mnt
mount --mkdir /dev/${disk}1 /mnt/boot
else
fdisk /dev/$disk <<EOF
g
n
1
2048
+512m
t
1
n
2
\n
+1g
n
3
\n
\n
w
EOF
mkfs.fat -F32 /dev/${disk}1 -n boot
mkswap /dev/${disk}2 -L swap
mkfs.ext4 /dev/${disk}3 -L root<<EOF
y
EOF
mount /dev/${disk}3 /mnt
mount --mkdir /dev/${disk}1 /mnt/boot
fi
