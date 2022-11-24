#!/bin/bash
username="virtual"
sysdisk="sda"
massdisks=$(lsblk -sno Name | grep -ivE "└─|$sysdisk|rom|usb")
echo -e $massdisks
for (( j=0, i=1; i<="${#massdisks[*]}"; i++, j++ ))
do
if [ -z $(lsblk -no LABEL /dev/${massdisks[$j]}) ];
then
echo ${massdisks[$j]}
mount --mkdir /mnt/dev/${massdisks[$j]} /mnt/home/$username/${massdisks[$j]}/
else
echo ${massdisks[$j]}
lsblk -no LABEL /dev/${massdisks[$j]}
mount --mkdir /mnt/dev/$(lsblk -no LABEL /dev/${massdisks[$j]}) /mnt/home/$username/$(lsblk -no LABEL /dev/${massdisks[$j]})/
fi
done
