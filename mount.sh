#!/bin/bash
#mount /dev/sda4 /mnt
#mount --mkdir /dev/sda1 /mnt/boot
#mount --mkdir /dev/sda5 /mnt/var
#mount --mkdir /dev/sda6 /mnt/home
#swapon /dev/sda3
for (( j=0, i=1; i<="${#massparts[*]}"; i++, j++ ))
    do
        if [ -z "$(lsblk -no LABEL /dev/"${massparts[$j]}")" ];
            then
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then arch-chroot /mnt mount -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /home/"$username"/Documents/Devices/"${massparts[$j]}"
                    else arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/Documents/Devices/"${massparts[$j]}"
                fi
masslabel+='
${execi 10 sudo smartctl -al scttempsts /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}°C ${color #f92b2b}~/Documents/Devices/'"${massparts[$j]}"'${hr 3}$color
(${fs_type ~/Documents/Devices/'"${massparts[$j]}"'})${fs_bar '"$font"','"$(($font*6))"' ~/Documents/Devices/'"${massparts[$j]}"'} $alignr${color #f92b2b}${fs_used ~/Documents/Devices/'"${massparts[$j]}"'} / $color${fs_free ~/Documents/Devices/'"${massparts[$j]}"'} / ${color #b2b2b2}${fs_size ~/Documents/Devices/'"${massparts[$j]}"'}'
            else
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then arch-chroot /mnt mount -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                    else arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                fi
masslabel+='
${execi 10 sudo smartctl -al scttempsts /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}°C ${color #f92b2b}~/Documents/Devices/'"${massparts[$j]}"'${hr 3}$color
(${fs_type ~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'})${fs_bar '"$font"','"$(($font*6))"' ~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}$alignr${fs_used ~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #f92b2b}${fs_free ~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / $color${fs_size ~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}'
  fi
    done