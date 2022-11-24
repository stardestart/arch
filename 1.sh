#!/bin/bash
username="virtual"
sysdisk="sda"
massdisks="$(lsblk -sn | grep -ivE "└─|$sysdisk|rom|usb|/" | awk '{print $1}')"
echo -e $massdisks
for (( j=0, i=1; i<="${#massdisks[*]}"; i++, j++ ))
do
if [ -z "$(lsblk -no LABEL /dev/"${massdisks[$j]}")" ];
then
echo "${massdisks[$j]}"
arch-chroot /mnt mount --mkdir /dev/"${massdisks[$j]}" /home/"$username"/"${massdisks[$j]}"/
else
echo "${massdisks[$j]}"
lsblk -no LABEL /dev/"${massdisks[$j]}"
arch-chroot /mnt mount --mkdir /dev/"${massdisks[$j]}" /home/"$username"/"$(lsblk -no LABEL /dev/"${massdisks[$j]}")"/
fi
done
