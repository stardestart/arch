#!/bin/bash
loadkeys ru
setfont ter-v18n
swapoff -a
umount -R /mnt
pacman -Scc --noconfirm
gpg-connect-agent reloadagent /bye
rm /var/lib/pacman/db.lck
rm -R /root/.gnupg/
rm -R /etc/pacman.d/gnupg/
mount -o remount,size=2G /run/archiso/cowspace
sed -i '/= Required DatabaseOptional/c\SigLevel = Required DatabaseOptional TrustAll' /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinux
pacman -Sy glibc --noconfirm
pacman -Sy lib32-glibc --noconfirm
