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
n
2

+1m
t
2
4
n
3

+1g
n
4


w
EOF
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

+1g
n
3


w
EOF
fi
