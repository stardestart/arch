#!/bin/bash
#
#Установим язык и шрифт консоли.
loadkeys ru
setfont ter-v18n
#
#Сброс переменных и размонтирование разделов, на случай повторного запуска скрипта.
echo -e "\033[36mСброс переменных и размонтирование разделов, на случай повторного запуска скрипта.\033[0m"
#Размонтирование swap раздела.
swapoff -a
#Размонтирование дисков.
umount -R /mnt
#Удаление ключей pacman.
rm -rf /etc/pacman.d/gnupg/*
pacman -Sc --noconfirm
killall gpg-agent
#Переменная назначит образ микрокода ЦП для UEFI загрузчика.
microcode=""
#Переменная сохранит имя wi-fi сети для дальнейшей установки/настройки/расчета.
namewifi=""
#Переменная сохранит пароль wi-fi сети для дальнейшей установки/настройки/расчета.
passwifi=""
#Переменная сохранит имя сетевого устройства для дальнейшей установки/настройки/расчета.
netdev=""
#Массив хранит имена обнаруженных дисков.
massdisks=()
#Переменная сохранит имя диска на который будет установлена ОС для дальнейшей установки/настройки/расчета.
sysdisk=""
#Массив хранит имена обнаруженных дисков с разделителями для передачи в grep фильтрацию.
grepmassdisks=()
#Массив хранит имена обнаруженных разделов дисков.
massparts=()
#Массив хранит метки обнаруженных разделов дисков, если такие имеются.
masslabel=()
#Переменные сохранят нумерацию системных разделов для дальнейшей установки/настройки/расчета (это необходимо в связи с тем что принцип нумерации nvme дисков отличается от остальных дисков).
p1=""
p2=""
p3=""
p4=""
#Переменная сохранит имя ПК для дальнейшей установки/настройки/расчета.
hostname=""
#Переменная сохранит имя пользователя для дальнейшей установки/настройки/расчета.
username=""
#Переменная сохранит пароль пользователя для дальнейшей установки/настройки/расчета.
passuser=""
#Переменная сохранит root пароль для дальнейшей установки/настройки/расчета.
passroot=""
#Переменная сохранит размер шрифта ОС для дальнейшей установки/настройки/расчета.
font=0
#Переменная сохранит размер окна терминала для дальнейшей установки/настройки/расчета.
xterm=""
#Переменная сохранит количество ОЗУ для дальнейшей установки/настройки/расчета.
ram=0
#Переменная сохранит размер swap раздела для дальнейшей установки/настройки/расчета.
swap=0
#Массив сохранит количество ядер ЦП для дальнейшей установки/настройки/расчета.
coremass=()
#Массив формирует данные для передачи их в конфиг приложения отслеживающему температуру ядер ЦП.
coremassconf=()
#Переменная сохранит наличие видеокарты nvidia для дальнейшей установки/настройки/расчета.
nvidiac=""
#Обратный отсчет.
tic=3
#Массив хранит наличие ssd, если такие имеются.
massd=()
#
#Переменная сохранит размер шрифта firefox.
fox=""
#
#Определяем процессор.
echo -e "\033[36mОпределяем процессор.\033[0m"
if [ -n "$(lscpu | grep -i amd)" ]; then microcode="\ninitrd /amd-ucode.img"
elif [ -n "$(lscpu | grep -i intel)" ]; then microcode="\ninitrd /intel-ucode.img"
fi
echo -e "\033[36mПроцессор:"$(lscpu | grep -i "model name")"\033[0m"
#
#Определяем сетевое устройство.
echo -e "\033[36mОпределяем сетевое устройство.\033[0m"
if [ -n "$(iwctl device list | awk '{print $2}' | grep wl | head -n 1)" ];
    then
        echo -e "\033[47m\033[30mОбнаружен wifi модуль, если основное подключение к интернету планируется через wifi введите имя сети, если через провод нажмите Enter:\033[0m\033[32m";read -p ">" namewifi
        netdev="$(iwctl device list | awk '{print $2}' | grep wl | head -n 1)"
fi
if [ -z "$namewifi" ];
    then
        netdev="$(ip -br link show | grep -vEi "unknown|down" | awk '{print $1}' | xargs)"
    else
        echo -e "\033[47m\033[30mПароль wifi:\033[0m\033[32m";read -p ">" passwifi
        iwctl --passphrase "$passwifi" station "$netdev" connect "$namewifi"
fi
echo -e "\033[36mСетевое устройство:"$netdev"\033[0m"
#
#Определяем часовой пояс.
echo -e "\033[36mОпределяем часовой пояс.\033[0m"
timedatectl set-timezone "$(curl https://ipapi.co/timezone)"
echo -e "\033[36mЧасовой пояс:"$(curl https://ipapi.co/timezone)"\033[0m"
#
#Определяем физический диск на который будет установлена ОС.
echo -e "\033[36mОпределяем физический диск на который будет установлена ОС.\033[32m"
massdisks=($(lsblk -fno +tran,type | grep -ivE "├─|└─|rom|usb|/|SWAP|part" | awk '{print $1}'))
if [ "${#massdisks[*]}" = 1 ]; then sysdisk="${massdisks[0]}"
elif [ "${#massdisks[*]}" = 0 ];
    then
        echo -e "\033[41m\033[30mДоступных дисков не обнаружено!\033[0m"
        exit 0
    else
        PS3="$(echo -e "\033[47m\033[30mПункт №:\033[0m\n\033[32m")"
        menu_from_array () {
            select item; do
                if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
                    echo -e "\033[36mДиск на который будет установлена ОС:\n\033[32m$item\033[0m"
                    sysdisk="${massdisks[$(($REPLY - 1))]}"
                    break;
                else
                    echo -e "\033[41m\033[30mЧто значит - "$REPLY"? До $# посчитать не можешь и Arch Linux ставишь?\033[0m\033[32m"
                fi
        done }
        for (( j=0, i=1; i<="${#massdisks[*]}"; i++, j++ ))
            do
                grepmassdisks+=("$(lsscsi -st | grep -i "${massdisks[$j]}")")
            done
        menu_from_array "${grepmassdisks[@]}"
        massdisks=( ${massdisks[@]/$sysdisk} )
        for (( j=0, i=1; i<="${#massdisks[*]}"; i++, j++ ))
            do
                if [ -z "$(fdisk -l /dev/"${massdisks[$j]}" | awk '/^\/dev\//' | awk '{print $1}' | cut -b6-15)" ];
                    then
                        massparts+=("${massdisks[$j]}")
                    else
                        massparts+=($(fdisk -l /dev/"${massdisks[$j]}" | awk '/^\/dev\//' | awk '{print $1}' | cut -b6-15))
                fi
            done
fi
echo -e "\033[36mФизический диск на который будет установлена ОС:"$sysdisk"\033[0m"
#
#Определяем есть ли nvme контролер системного диска.
echo -e "\033[36mОпределяем, есть ли nvme контролер системного диска.\033[0m"
if [ -z "$(echo "$sysdisk" | grep -i "nvme")" ];
    then
        p1="1"
        p2="2"
        p3="3"
        p4="4"
    else
        p1="p1"
        p2="p2"
        p3="p3"
        p4="p4"
fi
#
#Сбор данных пользователя.
echo -e "\033[47m\033[30mВведите имя компьютера:\033[0m\033[32m";read -p ">" hostname
echo -e "\033[47m\033[30mВведите имя пользователя:\033[0m\033[32m";read -p ">" username
echo -e "\033[47m\033[30mВведите пароль для "$username":\033[0m\033[32m";read -p ">" passuser
echo -e "\033[47m\033[30mВведите пароль для root:\033[0m\033[32m";read -p ">" passroot
echo -e "\033[36mВыберите разрешение монитора:\033[32m"
PS3="$(echo -e "\033[47m\033[30mПункт №:\033[0m\n\033[32m")"
select menuscreen in "~480p." "~720p-1080p." "~4K."
do
    case "$menuscreen" in
        "~480p.")
            font=8
            xterm="700 350"
            fox=0.0
            break
            ;;
        "~720p-1080p.")
            font=10
            xterm="1000 500"
            fox=1.0
            break
            ;;
        "~4K.")
            font=12
            xterm="2000 1000"
            fox=1.5
            break
            ;;
        *) echo -e "\033[41m\033[30mЧто значит - "$REPLY"? До трёх посчитать не можешь и Arch Linux ставишь?\033[0m\033[32m";;
    esac
done
#
#Вычисление swap.
echo -e "\033[36mВычисление swap.\033[0m"
ram="$(free -g | grep -i mem | awk '{print $2}')"
if [ "$ram" -ge 128 ]; then swap="11G"
elif [ "$ram" -ge 64 ]; then swap="8G"
elif [ "$ram" -ge 32 ]; then swap="6G"
elif [ "$ram" -ge 24 ]; then swap="5G"
elif [ "$ram" -ge 16 ]; then swap="4G"
elif [ "$ram" -ge 12 ]; then swap="3G"
elif [ "$ram" -ge 6 ]; then swap="2G"
elif [ "$ram" -lt 6 ]; then swap="1G"
fi
echo -e "\033[36mРазмер SWAP раздела: $swap\033[0m"
#
#Разметка системного диска.
echo -e "\033[36mРазметка системного диска.\033[0m"
if [ -z "$(efibootmgr | grep Boot)" ];
    then
        echo -e "\033[36mLegacy boot.\033[0m"
fdisk /dev/"$sysdisk"<<EOF
g
n
1
2048
+512M
n
2

+1M
t
2
4
n
3

+$swap
n
4


w
EOF
mkfs.ext2 /dev/"$sysdisk""$p1" -L boot<<EOF
y
EOF
mkswap /dev/"$sysdisk""$p3" -L swap
mkfs.ext4 /dev/"$sysdisk""$p4" -L root<<EOF
y
EOF
mount /dev/"$sysdisk""$p4" /mnt
mount --mkdir /dev/"$sysdisk""$p1" /mnt/boot
swapon /dev/"$sysdisk""$p3"
    else
        echo -e "\033[36mUEFI boot.\033[0m"
fdisk /dev/"$sysdisk"<<EOF
g
n
1
2048
+512M
t
1
n
2

+$swap
n
3


w
EOF
mkfs.fat -F32 /dev/"$sysdisk""$p1" -n boot<<EOF
y
EOF
mkswap /dev/"$sysdisk""$p2" -L swap
mkfs.ext4 /dev/"$sysdisk""$p3" -L root<<EOF
y
EOF
mount /dev/"$sysdisk""$p3" /mnt
mount --mkdir /dev/"$sysdisk""$p1" /mnt/boot
swapon /dev/"$sysdisk""$p2"
fi
#
#Установка и настройка программы для фильтрования зеркал и обновление ключей.
echo -e "\033[36mУстановка и настройка программы для фильтрования зеркал и обновление ключей.\033[0m"
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --color always gnupg archlinux-keyring --noconfirm
pacman -Sy --color always reflector --noconfirm
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
#
#Установка ОС.
echo -e "\033[36mУстановка ОС.\033[0m"
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware
#
#Установка часового пояса.
echo -e "\033[36mУстановка часового пояса.\033[0m"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$(curl https://ipapi.co/timezone)" /etc/localtime
arch-chroot /mnt hwclock --systohc
#
#Настройка локали.
echo -e "\033[36mНастройка локали.\033[0m"
arch-chroot /mnt sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
arch-chroot /mnt sed -i 's/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
echo -e "LANG=\"ru_RU.UTF-8\"" > /mnt/etc/locale.conf
echo -e "KEYMAP=ru\nFONT=ter-v18n\nUSECOLOR=yes" > /mnt/etc/vconsole.conf
arch-chroot /mnt locale-gen
#
#Имя ПК.
echo "$hostname" > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 "$hostname".localdomain "$hostname"" > /mnt/etc/hosts
#
#ROOT пароль.
arch-chroot /mnt passwd<<EOF
$passroot
$passroot
EOF
#
#Создание пользователя.
echo -e "\033[36mСоздание пользователя.\033[0m"
arch-chroot /mnt useradd -m -g users -G wheel -s /bin/bash "$username"
#
#Пароль пользователя.
arch-chroot /mnt passwd "$username"<<EOF
$passuser
$passuser
EOF
#
#Убираем sudo пароль для пользователя.
echo ""$username" ALL=(ALL:ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
#
#Установим загрузчик.
echo -e "\033[36mУстановка загрузчика.\033[0m"
if [ -z "$(efibootmgr | grep Boot)" ];
    then
        arch-chroot /mnt pacman -Sy --color always grub --noconfirm
        arch-chroot /mnt grub-install /dev/"$sysdisk"
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    else
        arch-chroot /mnt pacman -Sy --color always efibootmgr --noconfirm
        arch-chroot /mnt bootctl install
        echo -e "default arch\ntimeout 2\neditor yes\nconsole-mode max" > /mnt/boot/loader/loader.conf
        echo -e "title  Arch Linux\nlinux  /vmlinuz-linux-zen"$microcode"\ninitrd  /initramfs-linux-zen.img\noptions root=/dev/"$sysdisk""$p3" rw" > /mnt/boot/loader/entries/arch.conf
fi
#
#Установим микроинструкции для процессора.
echo -e "\033[36mУстановка микроинструкций для процессора.\033[0m"
if [ "$microcode" = "\ninitrd /amd-ucode.img" ]; then arch-chroot /mnt pacman -Sy --color always amd-ucode --noconfirm
elif [ "$microcode" = "\ninitrd /intel-ucode.img" ]; then arch-chroot /mnt pacman -Sy --color always intel-ucode iucode-tool --noconfirm
fi
#
#Настройка установщика.
echo -e "\033[36mНастройка установщика.\033[0m"
arch-chroot /mnt sed -i "s/#Color/Color/" /etc/pacman.conf
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
#
#Настройка sysrq.
echo -e "\033[36mНастройка sysrq.\033[0m"
echo "kernel.sysrq=1" > /mnt/etc/sysctl.d/99-sysctl.conf
#
#Установка программ.
echo -e "\033[36mУстановка программ.\033[0m"
arch-chroot /mnt pacman --color always -Sy nano dhcpcd xorg i3-gaps xorg-xinit xterm dmenu xdm-archlinux i3status git firefox numlockx gparted kwalletmanager ark mc htop conky polkit dmg2img dolphin kdf filelight ifuse usbmuxd libplist libimobiledevice curlftpfs samba kimageformats ffmpegthumbnailer kdegraphics-thumbnailers qt5-imageformats kdesdk-thumbnailers ffmpegthumbs ntfs-3g dosfstools kde-cli-tools papirus-icon-theme picom redshift lxqt-panel grc flameshot xscreensaver notification-daemon qgnomeplatform-qt5 gnome-themes-extra archlinux-wallpaper feh alsa-utils alsa-plugins lib32-alsa-plugins alsa-firmware alsa-card-profiles pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol-qt freetype2 ttf-fantasque-sans-mono audacity kdenlive cheese kate sweeper pinta gimp transmission-qt vlc libreoffice-still-ru obs-studio ktouch kalgebra avidemux-qt copyq blender telegram-desktop discord marble step kontrast kamera kcolorchooser gwenview imagemagick xreader sane skanlite cups cups-pdf steam wine winetricks wine-mono wine-gecko mesa lib32-mesa go wireless_tools avahi libnotify reflector smartmontools autocutsel tesseract-data-eng tesseract-data-rus openssh meld clinfo unzip haveged dbus-broker gamemode lib32-gamemode perl-anyevent-i3 perl-json-xs system-config-printer network-manager-applet bluedevil --noconfirm
arch-chroot /mnt pacman -Ss geoclue2
#
#Установим видеодрайвер.
echo -e "\033[36mУстановка видеодрайвера.\033[0m"
if [ -n "$(lspci | grep -i vga | grep -i amd)" ]; then arch-chroot /mnt pacman --color always -Sy vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i ' ati ')" ]; then arch-chroot /mnt pacman --color always -Sy xf86-video-ati libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then arch-chroot /mnt pacman --color always -Sy nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia opencv-cuda nvtop cuda --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i intel)" ]; then arch-chroot /mnt pacman --color always -Sy xf86-video-intel vulkan-intel --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i 'vmware svga')" ]; then arch-chroot /mnt pacman --color always -Sy virtualbox-guest-utils --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i virtualbox )" ]; then arch-chroot /mnt pacman --color always -Sy virtualbox-guest-utils --noconfirm
fi
#
#Проверка наличия температурного датчика у системного диска.
if [ -n "$(arch-chroot /mnt smartctl -al scttempsts /dev/"$sysdisk" | grep -i temperature: -m 1 | awk '!($NF="")' | awk '{print $NF}')" ];
    then
sysdisktemp+='
${color #b2b2b2}Температура:$color$alignr${execi 10 sudo smartctl -al scttempsts /dev/'"$sysdisk"' | grep -i temperature: -m 1 | awk \047!($NF="")\047 | awk \047{print $NF}\047}°C'
fi
#
#Поиск не смонтированных разделов, проверка наличия у них температурного датчика и метки.
echo -e "\033[36mПоиск не смонтированных разделов.\033[0m"
masslabel+='
#Блок "Диски и разделы".'
for (( j=0, i=1; i<="${#massparts[*]}"; i++, j++ ))
    do
        if [ -z "$(lsblk -no LABEL /dev/"${massparts[$j]}")" ];
            then
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then arch-chroot /mnt mount -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /home/"$username"/"${massparts[$j]}"
                    else arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/"${massparts[$j]}"
                fi
masslabel+='
${color #f92b2b}/home/'"$username"'/'"${massparts[$j]}"'${hr 3}'
                if [ -n "$(arch-chroot /mnt smartctl -al scttempsts /dev/"${massparts[$j]}" | grep -i temperature: -m 1 | awk '!($NF="")' | awk '{print $NF}')" ];
                    then
masslabel+='
${color #b2b2b2}Температура:$color$alignr${execi 10 sudo smartctl -al scttempsts /dev/'"${massparts[$j]}"' | grep -i temperature: -m 1 | awk \047!($NF="")\047 | awk \047{print $NF}\047}°C'
                fi
masslabel+='
${color #b2b2b2}Объём:$alignr${fs_size /home/'"$username"'/'"${massparts[$j]}"'} / ${color #f92b2b}${fs_used /home/'"$username"'/'"${massparts[$j]}"'} / $color${fs_free /home/'"$username"'/'"${massparts[$j]}"'}
(${fs_type /home/'"$username"'/'"${massparts[$j]}"'})${fs_bar 4 /home/'"$username"'/'"${massparts[$j]}"'}'
                if [ -n "$(arch-chroot /mnt smartctl -al scttempsts /dev/"${massparts[$j]}" | grep -i temperature: -m 1 | awk '!($NF="")' | awk '{print $NF}')" ];
                    then
masslabel+='
${color #b2b2b2}Температура:$color$alignr${execi 10 sudo smartctl -al scttempsts /dev/'"${massparts[$j]}"' | grep -i temperature: -m 1 | awk \047!($NF="")\047 | awk \047{print $NF}\047}°C'
                fi
            else
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then arch-chroot /mnt mount -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /home/"$username"/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                    else arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                fi
masslabel+='
${color #f92b2b}/home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'${hr 3}'
                if [ -n "$(arch-chroot /mnt smartctl -al scttempsts /dev/"${massparts[$j]}" | grep -i temperature: -m 1 | awk '!($NF="")' | awk '{print $NF}')" ];
                    then
masslabel+='
${color #b2b2b2}Температура:$color$alignr${execi 10 sudo smartctl -al scttempsts /dev/'"${massparts[$j]}"' | grep -i temperature: -m 1 | awk \047!($NF="")\047 | awk \047{print $NF}\047}°C'
                fi
masslabel+='
${color #b2b2b2}Объём:$alignr${fs_size /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #f92b2b}${fs_used /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / $color${fs_free /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}
(${fs_type /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'})${fs_bar 4 /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}'
        fi
    done
#
#Копирование файла автоматического монтирования разделов.
echo -e "\033[36mПеренос genfstab.\033[0m"
genfstab -U /mnt >> /mnt/etc/fstab
#
#Создание общего конфига загрузки оконного менеджера.
echo -e "\033[36mСоздание xinit.\033[0m"
echo '#Указание на конфигурационные файлы.
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap
#Объединить значения по умолчанию и раскладки клавиш.
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi
if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi
if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi
if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi
#Запуск программ.
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi
xhost +si:localuser:root #Позволяет пользователю root получить доступ к работающему X-серверу.
feh --bg-max --randomize --no-fehbg /usr/share/backgrounds/archlinux/ & #Автозапуск обоев рабочего стола.
exec i3 #Автозапуск i3.' > /mnt/home/"$username"/.xinitrc
#
#Создание общего конфига клавиатуры.
echo -e "\033[36mСоздание 00-keyboard.\033[0m"
echo 'Section "InputClass"
Identifier "system-keyboard"
MatchIsKeyboard "on"
Option "XkbLayout" "us,ru"
Option "XkbOptions" "grp:alt_shift_toggle,terminate:ctrl_alt_bksp"
EndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
#
#Создание общего конфига сканера.
echo -e "\033[36mСоздание sane.d.\033[0m"
mkdir -p /mnt/etc/sane.d
echo -e "localhost\n192.168.0.0/24" >> /mnt/etc/sane.d/net.conf
#
echo -e "\033[36mФормируется конфиг conky.\033[0m"
#
#Температура ядер процессора.
if [ -n "$(arch-chroot /mnt sensors | grep Core | awk '{print $1}' | xargs)" ]; then
coremass=($(arch-chroot /mnt sensors | grep Core | awk '{print $1}' | xargs))
coremassconf+='
#Температура ядер ЦП.
${color #b2b2b2}Температура ядер ЦП:$color'
for (( i=0, j=1; j<="${#coremass[*]}"; i++, j++ ))
    do
        coremassconf+='
$alignr${execi 10 sensors | grep "Core '$i':" | awk \047{print $1, $2, $3}\047}'
    done
fi
#
#Параметры для видеокарт nvidia.
if [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then
    nvidiac='
#Блок "Видеокарта Nvidia".
${color #f92b2b}GPU${hr 3}
${color #b2b2b2}Частота ГП:$color$alignr${nvidia gpufreq} Mhz
${color #b2b2b2}Видео ОЗУ:$color$alignr${nvidia mem} / ${nvidia memmax} MiB
${color #b2b2b2}Температура ГП:$color$alignr${nvidia temp} °C'
fi
#
#Создание директории и конфига.
mkdir -p /mnt/home/"$username"/.config/conky
echo -e 'conky.config = { --Внешний вид.
alignment = "top_right", --Располжение виджета.
border_inner_margin = '"$font"', --Отступ от внутренних границ.
border_outer_margin = '"$font"', --Отступ от края окна.
cpu_avg_samples = 2, --Усреднение значений нагрузки.
default_color = "#2bf92b", --Цвет по умолчанию.
double_buffer = true, --Включение двойной буферизации.
draw_shades = false, --Оттенки.
font = "Fantasque Sans Mono:bold:size='"$font"'", --Шрифт и размер шрифта.
gap_y = '"$(($font*7))"', --Отступ сверху.
gap_x = 40, --Отступ от края.
own_window = true, --Собственное окно.
own_window_class = "Conky", --Класс окна.
own_window_type = "override", --Тип окна (возможные варианты: "normal", "desktop", "dock", "panel", "override" выбираем в зависимости от оконного менеджера и личных предпочтений).
own_window_hints = "undecorated, skip_taskbar", --Задаем эфекты отображения окна.
own_window_argb_visual = true, --Прозрачность окна.
own_window_argb_value = 70, --Уровень прозрачности.
use_xft = true, } --Использование шрифтов X сервера.
conky.text = [[ #Наполнение виджета.
#Блок "Время".
#Часы.
${font Fantasque Sans Mono:bold:italic:size='"$(($font*3))"'}$alignc${color #f92b2b}$alignc${time %H:%M}$font$color
#Дата.
${font Fantasque Sans Mono:bold:italic:size='"$(($font*2))"'}$alignc${color #b2b2b2}${time %d %b %Y} (${time %a})$font$color
#Блок "Система".
#Разделитель.
${color #f92b2b}Система${hr 3}$color
#Ядро.
${color #b2b2b2}Ядро:$color$alignr$kernel
#Время в сети.
${color #b2b2b2}Время в сети:$color$alignr$uptime
#Блок "ЦП".
#Разделитель.
${color #f92b2b}ЦП${hr 3}$color
#Нагрузка ЦП.
${color #b2b2b2}Нагрузка ЦП:$color$alignr$cpu %
#Частота ЦП.
${color #b2b2b2}Частота ЦП:$color$alignr$freq MHz'"${coremassconf[@]}"''"$nvidiac"'
#Блок "ОЗУ".
#Разделитель.
${color #f92b2b}ОЗУ${hr 3}$color
#ОЗУ.
${color #b2b2b2}ОЗУ:$alignr$memmax / ${color #f92b2b}$mem / $color$memeasyfree
#Полоса загрузки ОЗУ.
$memperc%${membar 4}
#Блок "Раздел подкачки".
#Разделитель.
${color #f92b2b}Раздел подкачки${hr 3}$color
#Задействовано Подкачки.
${color #b2b2b2}Задействовано:$color$alignr$swap / $swapmax
#Полоса загрузки Подкачки.
$swapperc%${swapbar 4}
#Блок "Сеть".
#Разделитель.
${color #f92b2b}Сеть${hr 3}$color
#Скорость приёма ('"$netdev"' определенно командой "ls /sys/class/net" в терминале).
${color #b2b2b2}Скорость приёма:$color$alignr${upspeedf '"$netdev"'}
#Скорость отдачи.
${color #b2b2b2}Скорость отдачи:$color$alignr${downspeedf '"$netdev"'}
#IP адрес.
${color #b2b2b2}IP адрес:$color$alignr${curl eth0.me}
#Блок "Процессы".
#Разделитель.
${color #f92b2b}Процессы${hr 3}$color
#Таблица процессов.
${color #b2b2b2}Название$alignr PID | CPU% | MEM% $color
#Информация о процессе 1.
${top name 1} $alignr ${top pid 1}|${top cpu 1}|${top mem 1}
#Информация о процессе 2.
${top name 2} $alignr ${top pid 2}|${top cpu 2}|${top mem 2}
#Информация о процессе 3.
${top name 3} $alignr ${top pid 3}|${top cpu 3}|${top mem 3}
#Информация о процессе 4.
${top name 4} $alignr ${top pid 4}|${top cpu 4}|${top mem 4}
#Информация о процессе 5.
${top name 5} $alignr ${top pid 5}|${top cpu 5}|${top mem 5}
#Блок "Системный диск".
#Разделитель.
${color #f92b2b}/home${hr 3}$color
#Общее/Занято/Свободно.
${color #b2b2b2}Объём:$alignr${fs_size /home} / ${color #f92b2b}${fs_used /home} / $color${fs_free /home}
#Полоса загрузки.
$color(${fs_type /home})${fs_bar 4 /home}'"$sysdisktemp"''"${masslabel[@]}"'
]]' > /mnt/home/"$username"/.config/conky/conky.conf
#
#Создание bash_profile.
echo -e "\033[36mСоздание bash_profile.\033[0m"
echo '[[ -f ~/.profile ]] && . ~/.profile' > /mnt/home/"$username"/.bash_profile
#
#Создание bashrc.
echo -e "\033[36mСоздание bashrc.\033[0m"
echo '[[ $- != *i* ]] && return #Определяем интерактивность шелла.
alias grep="grep --color=always" #Раскрашиваем grep.
alias ip="ip --color=always" #Раскрашиваем ip.
alias diff="diff --color=always" #Раскрашиваем diff.
alias ls="ls --color" #Раскрашиваем ls.
alias df="grc --colour=on df" #Раскрашиваем df.
alias zgrep="grc --colour=on zgrep" #Раскрашиваем zgrep.
alias cvs="grc --colour=on cvs" #Раскрашиваем cvs.
alias esperanto="grc --colour=on esperanto" #Раскрашиваем esperanto.
alias irclog="grc --colour=on irclog" #Раскрашиваем irclog.
alias ldap="grc --colour=on ldap" #Раскрашиваем ldap.
alias log="grc --colour=on log" #Раскрашиваем log.
alias netstat="grc --colour=on netstat" #Раскрашиваем netstat.
alias proftpd="grc --colour=on proftpd" #Раскрашиваем proftpd.
alias traceroute="grc --colour=on traceroute" #Раскрашиваем traceroute.
alias wdiff="grc --colour=on wdiff" #Раскрашиваем wdiff.
alias dig="grc --colour=on dig" #Раскрашиваем dig.
alias cat="grc --colour=on cat" #Раскрашиваем cat.
alias zcat="grc --colour=on zcat" #Раскрашиваем zcat.
alias make="grc --colour=on make" #Раскрашиваем make.
alias g++="grc --colour=on g++" #Раскрашиваем g++.
alias head="grc --colour=on head" #Раскрашиваем head.
alias mtr="grc --colour=on mtr" #Раскрашиваем mtr.
alias ping="grc --colour=on ping" #Раскрашиваем ping.
alias gcc="grc --colour=on gcc" #Раскрашиваем gcc.
alias mount="grc --colour=on mount" #Раскрашиваем mount.
alias ps="grc --colour=on ps" #Раскрашиваем ps.
#Изменяем вид приглашения командной строки.
PS1="\[\033[43m\]\[\033[2;34m\]\A\[\033[0m\]\[\033[44m\]\[\033[3;33m\] \u@\h \[\033[0m\]\[\033[2;41m\]\[\033[30m\] \W/ \[\033[0m\]\[\033[5;31m\] \$:\[\033[0m\]"
#\[\033[43m\] - Жёлтый цвет фона.
#\[\033[2;34m\] - 2 - Более темный цвет, 34 - Синий цвет.
#\A Текущее время в 24-часовом формате.
#\[\033[0m\] - Конец изменениям.
#\[\033[44m\] - Синий цвет фона.
#\[\033[3;33m\] - 3 - Курсив, 33 - Жёлтый цвет.
#\u@\h ИмяПользователя@ИмяХоста
#\[\033[0m\] - Конец изменениям.
#\[\033[2;41m\] - 2 - Более темный цвет, 41 - Красный цвет фона.
#\[\033[30m\]  - Черный цвет.
#\W  ТекущийОтносительныйПуть.
#\[\033[0m\] - Конец изменениям.
#\[\033[5;31m\] - 5 - моргание, 91 - красный цвет.
#\$: Символ приглашения (# для root, $ для обычных пользователей).
#\[\033[0m\] - Конец изменениям.
#Удаляем повторяющиеся записи и записи начинающиеся с пробела (например команды в mc) в .bash_history.
export HISTCONTROL="ignoreboth"
export COLORTERM=truecolor #Включаем все 16 миллионов цветов в эмуляторе терминала.' > /mnt/home/"$username"/.bashrc
#
#Создание profile.
echo -e "\033[36mСоздание profile.\033[0m"
echo '[[ -f ~/.bashrc ]] && . ~/.bashrc #Указание на bashrc.
export QT_QPA_PLATFORMTHEME=gnome #Изменение внешнего вида приложений использующих qt.
export QT_STYLE_OVERRIDE=adwaita-dark #Использовать Adwaitа в качестве стиля Qt по умолчанию' > /mnt/home/"$username"/.profile
#
#Создание конфига сервера уведомлений.
echo -e "\033[36mСоздание конфига сервера уведомлений.\033[0m"
echo '[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/notification-daemon-1.0/notification-daemon' > /mnt/usr/share/dbus-1/services/org.freedesktop.Notifications.service
#
#Создание конфига picom.
echo -e "\033[36mСоздание конфига picom.\033[0m"
echo -e '# Прозрачность активных окон (0,1–1,0).
active-opacity = 0.9;
#
# Прозрачность неактивных окон (0,1–1,0).
inactive-opacity = 0.8;
#
# Затемнение неактивных окон (0,0–1,0).
inactive-dim = 0.4;
#
# Включить вертикальную синхронизацию (если picom выдает ошибку по vsync, то отключаем заменой true на false).
vsync = true;
#
# Отключить прозрачность и затемнение загаловков окон.
mark-ovredir-focused = true;
#
#Пусть неактивная непрозрачность, переопределяет значения окон.
inactive-opacity-override = false;
#
wintypes: { # Отключить прозрачность выпадающего меню.
            dropdown_menu = { opacity = 1; };
            # Отключить прозрачность всплывающего меню.
            popup_menu = { opacity = 1; }; };
#
# Прозрачность i3status, dmenu, XTerm и заголовков окон.
opacity-rule = [ "70:class_g = \047i3bar\047",
                 "90:class_g = \047dmenu\047",
                 "70:class_g = \047XTerm\047",
                 "80:class_g = \047i3-frame\047",
                 "100:class_g = \047vlc\047",
                 "100:fullscreen" ];
#
#Закругленные углы.
corner-radius = 5;
rounded-corners-exclude = [ "window_type = \047dock\047" ];
#
#Обнаруживает дочерние окна.
mark-wmwin-focused = true;
#
#Обнаруживает окна со скругленными углами и не учитывает их.
detect-rounded-corners = true;
#
#Обнаружение прозрачности в клиентских окнах.
detect-client-opacity = true;
#
#Отменить перенаправление всех окон, если обнаружено полноэкранное непрозрачное окно.
unredir-if-possible = true;
#
#Обнаружение групп окон.
detect-transient = true;
detect-client-leader = true;
#
#Отключить информацию о повреждениях, каждый раз перерисовывается весь экран, а не его часть.
use-damage = true;
#
#TechnicalSymbol #Размытие.
#TechnicalSymbol backend = "glx"
#TechnicalSymbol glx-no-stencil = true;
#TechnicalSymbol glx-no-rebind-pixmap = true;
#TechnicalSymbol blur:{ method = "dual_kawase";
#TechnicalSymbol       strength = 5;
#TechnicalSymbol       background = false;
#TechnicalSymbol       background-frame = false;
#TechnicalSymbol       background-fixed = false; }
#TechnicalSymbol       blur-background-exclude = [ "window_type = \047dock\047",
#TechnicalSymbol                            "window_type = \047notification\047",
#TechnicalSymbol                            "window_type = \047tooltip\047",
#TechnicalSymbol                            "class_g = \047Conky\047",
#TechnicalSymbol                            "class_g = \047i3bar\047",
#TechnicalSymbol                            "class_g = \047vlc\047",
#TechnicalSymbol                            "_NET_WM_STATE@:a != \047_NET_WM_STATE_FOCUSED\047" ];
' > /mnt/home/"$username"/.config/picom.conf
#
#Создание xresources.
echo -e "\033[36mСоздание xresources.\033[0m"
echo '!Настройка внешнего вида xterm.
!
!Задает имя типа терминала, которое будет установлено в переменной среды TERM.
xterm*termName: xterm-256color
!
!Xterm будет использовать кодировку, указанную в локали пользователя.
xterm*locale: true
!
!Определяет количество строк, сохраняемых за пределами верхней части экрана, когда включена полоса прокрутки.
xterm*saveLines: 10000
!
!Шрифт xterm.
xterm*faceName: Fantasque Sans Mono:style=bold:size='"$font"'
!
!Указывает цвет фона.
xterm*background: #2b2b2b
!Определяет цвет, который будет использоваться для переднего плана.
xterm*foreground: #2bf92b
!
!Указывает, должна ли отображаться полоса прокрутки.
xterm*scrollBar: false
!
!Указывает, должно ли нажатие клавиши автоматически перемещать полосу прокрутки в нижнюю часть области прокрутки.
xterm*scrollKey: true
!
!Размер курсора.
Xcursor.size: '"$(($font*3))"'
Xcursor.theme: Adwaita
!
!
!Настройка внешнего вида xscreensaver.
!
!Указывает шрифт.
xscreensaver-auth.?.Dialog.headingFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.Dialog.bodyFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.Dialog.labelFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.Dialog.unameFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.Dialog.buttonFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.Dialog.dateFont: Fantasque Sans Mono Bold Italic '"$font"'
xscreensaver-auth.?.passwd.passwdFont: Fantasque Sans Mono Bold Italic '"$font"'
!
!Указывает цвета.
xscreensaver-auth.?.Dialog.foreground: #b2f9b2
xscreensaver-auth.?.Dialog.background: #2b2b2b
xscreensaver-auth.?.Dialog.Button.foreground: #2b2b2b
xscreensaver-auth.?.Dialog.Button.background: #b2f9b2
xscreensaver-auth.?.Dialog.text.foreground: #2b2b2b
xscreensaver-auth.?.Dialog.text.background: #b2f9b2
xscreensaver-auth.?.passwd.thermometer.foreground: #f92b2b
xscreensaver-auth.?.passwd.thermometer.background: #b2f9b2' > /mnt/home/"$username"/.Xresources
#
#Создание директории и конфига i3.
echo -e "\033[36mСоздание конфига i3.\033[0m"
mkdir -p /mnt/home/"$username"/.config/i3
echo -e '########### Основные настройки ###########
#
# Назначаем клавишу MOD, Mod4 - это клавиша WIN.
set $mod Mod4
#
# Закрыть окно в фокусе.
bindsym $mod+Shift+q kill
#
# Изменить фокус на другое окно
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
#
# Переместить окно.
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
#
# Следующее открытое окно разделит экран по горизонтали (такое деление установленно по умолчанию). Легко запомнить по первой букве Horizontal.
bindsym $mod+h split h
#
# Следующее открытое окно разделит экран по вертикали. Легко запомнить по первой букве Vertical.
bindsym $mod+v split v
#
# Развернуть окно во весь экран. Легко запомнить по первой букве Fullscreen.
bindsym $mod+f fullscreen toggle
#
# Делаем из окон вкладки.
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
#
# ScrollDown на заголовке закрыть окно.
bindsym button5 kill
# ScrollUP на заголовке развернуть окно во весь экран.
bindsym button4 fullscreen toggle
# Правая кнопка мыши делает окно плавающим.
bindsym button3 floating toggle
# Средняя кнопка мыши сворачивает окно в черновик.
bindsym button2 move scratchpad
#
# Определяем имена для рабочих областей по умолчанию.
set $ws1 "1"
set $ws2 "2: 🌍"
set $ws3 "3: 🎮"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"
#
# Переключение между рабочими столами.
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10
#
# Переместить сфокусированное окно на заданный рабочий стол.
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10
#
# Перечитать файл конфигурации.
bindsym $mod+Shift+c reload
#
# Перезапустить i3 (сохраняет макет/сессию, может использоваться для обновления i3).
bindsym $mod+Shift+r restart
#
# Выход из i3 (выходит из сеанса X).
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m \047Вы действительно хотите выйти из i3? Это завершит вашу сессию X.\047 -B \047Да, выйти из i3\047 \047i3 -msg exit\047"
#
# Войти в режим изменения размеров окон.
bindsym $mod+r mode "resize"
# Изменить размер окна (можно использовать мышь).
mode "resize" {
#
        # Настройки смены размеров окон.
        bindsym Left resize shrink width 10 px or 5 ppt
        bindsym Down resize grow height 10 px or 5 ppt
        bindsym Up resize shrink height 10 px or 5 ppt
        bindsym Right resize grow width 10 px or 5 ppt
        #
        # Выйти из режима изменения размеров окон.
        bindsym $mod+r mode "default"
}
#
# Некоторые видеодрайверы X11 обеспечивают поддержку только Xinerama вместо RandR.
# В такой ситуации нужно сказать i3, чтобы он явно использовал подчиненный Xinerama API.
#force_xinerama yes
#
########### Внешний вид ###########
#
# Шрифт для заголовков окон. Также будет использоваться ibar, если не выбран другой шрифт.
font pango:Fantasque Sans Mono Bold '"$font"'
#
# Просветы между окнами.
gaps inner '"$font"'
#
# Толщина границы окна.
default_border normal 1
#
# Устанавливаем цвет рамки активного окна #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.focused #2b2b2b #2b2b2b #2bf92b #2b2b2b #2b2b2b
# Устанавливаем цвет рамки окна не в фокусе #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.unfocused #000000 #000000 #b2b2b2 #000000 #000000
# Устанавливаем цвет рамки неактивного окна в фокусе #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.focused_inactive #000000 #000000 #b2b2b2 #000000 #000000
# Устанавливаем цвет рамки важного окна #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.urgent #000000 #000000 #b2b2b2 #000000 #000000
# Устанавливаем цвет рамки окна-заполнитель #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.placeholder #000000 #000000 #b2b2b2 #000000 #000000
#
# Включить значки окон для всех окон с дополнительным горизонтальным отступом.
for_window [all] title_window_icon padding '"$font"'px
#
# Внешний вид XTerm
# Включить плавающий режим для всех окон XTerm.
for_window [class="XTerm"] floating enable
# Липкие плавающие окна, окно XTerm прилипло к стеклу.
for_window [class="XTerm"] sticky enable
# Задаем размеры окна XTerm.
for_window [class="XTerm"] resize set '"$xterm"'
#
########### Автозапуск программ ###########
#
# Запуск графического интерфейса системного трея NetworkManager (--no-startup-id убирает курсор загрузки).
exec --no-startup-id nm-applet
#
# Запуск геолокации (--no-startup-id убирает курсор загрузки).
exec --no-startup-id /usr/lib/geoclue-2.0/demos/agent
#
# Автозапуск flameshot.
exec --no-startup-id flameshot
#
# Автозапуск copyq и autocutsel.
exec --no-startup-id copyq
exec --no-startup-id autocutsel
#
# Автозапуск obs.
exec --no-startup-id obs
#
# Автозапуск lxqt-panel.
exec --no-startup-id lxqt-panel
#
# Автозапуск picom.
exec --no-startup-id picom -b
#
# Автозапуск conky.
exec --no-startup-id conky
#
# Автозапуск numlockx.
exec --no-startup-id numlockx
#
# Автозапуск transmission.
exec --no-startup-id transmission-qt -m
#
# Автозапуск blueman-applet.
exec --no-startup-id blueman-applet
#
# Приветствие в течении 10 сек.
exec --no-startup-id notify-send -te 10000 "✊Доброго времени суток✊" "ЛКМ на кнопке 🛈 -- Шпаргалка по i3wm."
#
# Автозапуск xscreensaver.
exec --no-startup-id xscreensaver --no-splash
#
# Автозапуск dolphin.
exec --no-startup-id dolphin --daemon
#
# Автозапуск steam.
exec --no-startup-id ENABLE_VKBASALT=1 gamemoderun steam -silent %U
#
# Автозапуск telegram.
exec --no-startup-id telegram-desktop -startintray -- %u
#
# Автоматическая разблокировка KWallet.
exec --no-startup-id /usr/lib/pam_kwallet_init
#
#Автозагрузка рабочего стола №1.
exec --no-startup-id ~/.config/i3/workspace.sh
#
########### Горячие клавиши запуска программ ###########
#
#Восстановление рабочего стола №1.
bindsym $mod+mod1+1 exec --no-startup-id ~/.config/i3/workspace.sh
#
# Используйте mod+enter, чтобы запустить терминал ("i3-sensible-terminal" можно заменить "xterm", "terminator" или любым другим на выбор).
bindsym $mod+Return exec xterm
#
# Запуск dmenu (программа запуска) с параметрами шрифта, приглашения, цвета фона.
bindsym $mod+d exec --no-startup-id dmenu_run -fn "Fantasque Sans Mono:style=bold:size='"$(($font/2+$font))"'" -p "Поиск программы:" -nb "#2b2b2b" -sf "#2b2bf9" -nf "#2bf92b" -sb "#f92b2b"
#
# Используйте mod+f1, чтобы запустить firefox.
bindsym $mod+F1 exec --no-startup-id firefox
#
# Сделать текущее окно черновиком/блокнотом.
bindsym $mod+Shift+minus move scratchpad
#
# Показать первое окно черновика/блокнота.
bindsym $mod+minus scratchpad show
#
# Снимок экрана.
bindsym Print exec flameshot full
#
########### Распределение окон по рабочим столам ###########
#
# Firefox будет запускаться на 2 рабочем столе.
assign [class="firefox"] "2: 🌍"
#
# Steam будет запускаться на 3 рабочем столе.
assign [title="Steam"] "3: 🎮"
#
########### Настройка панели задач ###########
#
bar {
        # Назначить панели задач.
        status_command i3status
        #
        # Разделитель.
        separator_symbol "☭"
        #
        # Назначить шрифт.
        font pango:Fantasque Sans Mono Bold Italic '"$font"'
        #
        # Назначить цвета.
        colors {
            # Цвет фона i3status.
            background #2b2b2b
            # Цвет текста в i3status.
            statusline #b2b2b2
            # Цвет разделителя в i3status.
            separator #f92b2b
            # Цвет границы, фона и текста для кнопки активного рабочего стола.
            focused_workspace  #4c7899 #285577 #f92b2b
            # Цвет границы, фона и текста для кнопки не активного рабочего стола.
            inactive_workspace #333333 #222222 #2bf92b
            }
         # Сделайте снимок экрана, щелкнув правой кнопкой мыши на панели (--no-startup-id убирает курсор загрузки).
         bindsym --release button3 exec --no-startup-id import ~/latest-screenshot.png
}
exec --no-startup-id firefox #TechnicalString
exec --no-startup-id xscreensaver-settings #TechnicalString
exec --no-startup-id xterm -e /bin/bash -l -c ~/archinstall.sh #TechnicalString' > /mnt/home/"$username"/.config/i3/config
#
#Создание конфига i3status.
echo -e "\033[36mСоздание конфига i3status.\033[0m"
echo 'general { #Основные настройки.
    colors = true #Включение/выключение поддержки цветов.
    color_good = "#2bf92b" #Цвет OK.
    color_bad = "#f92b2b" #Цвет ошибки.
    interval = 1 #Интервал обновления строки статуса.
    output_format = "i3bar" } #Формат вывода.
order += "tztime 0" #0 модуль - пробел.
order += "ethernet _first_" #1 модуль - rj45.
order += "wireless _first_" #2 модуль - Wi-Fi.
order += "battery all" #3 модуль - батарея.
order += "memory" #4 модуль - ram.
order += "cpu_usage" #5 модуль - использование ЦП.
order += "cpu_temperature 0" #6 модуль - температура ЦП.
order += "tztime 1" #7 модуль - дата.
order += "tztime 2" #8 модуль - время.
order += "tztime 0" #0 модуль - пробел.
ethernet _first_ { #Индикатор rj45.
    format_up = "🌐: %ip " #Формат вывода.
    format_down = "" } #При неактивном процессе блок будет отсутствовать.
wireless _first_ { #Индикатор WI-FI.
    format_up = "📶: %quality | %frequency | %essid: %ip " #Формат вывода.
    format_down = "" } #При неактивном процессе блок будет отсутствовать.
battery all { #Индикатор батареи
    format = "%status %percentage" #Формат вывода.
    last_full_capacity = true #Процент заряда.
    format_down = "" #При неактивном процессе блок будет отсутствовать.
    status_chr = "🔌" #Подзарядка.
    status_bat = "🔋" #Режим работы от батареи.
    path = "/sys/class/power_supply/BAT%d/uevent" #Путь данных.
    low_threshold = 10 } #Нижний порог заряда.
memory { #Индикатор ОЗУ
    format = "📥: %used / %total" #Формат вывода.
    threshold_degraded = 10% #Желтый порог.
    threshold_critical = 5% #Красный порог.
    format_degraded = "📥: %used / %total" } #Формат вывода желтого/красного порога.
cpu_usage { #Использование ЦП.
    format = "↯🧠: %usage" } #Формат вывода.
cpu_temperature 0 { #Температура ЦП.
    format = "🌡🧠: %degrees°C" #Формат вывода.
    max_threshold = "70" #Красный порог.
    format_above_threshold = "🌡🧠: %degrees°C" #Формат вывода красного порога.
    path = "/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input" } #Путь данных.path: /sys/devices/platform/coretemp.0/temp1_input
tztime 1 { #Вывод даты и времени.
    format = "📆 %a %d-%m-%Y(%W)" } #Формат вывода.
tztime 2 { #Вывод даты и времени.
    format = "🕓 %H:%M:%S %Z" } #Формат вывода.
tztime 0 { #Вывод разделителя.
    format = "|" } #Формат вывода.' > /mnt/home/"$username"/.i3status.conf
#
#Создание конфига redshift.
echo -e "\033[36mСоздание конфига redshift.\033[0m"
echo '[redshift]
allowed=true
system=false
users=' >> /mnt/etc/geoclue/geoclue.conf
#
#Отключение запроса пароля.
echo -e "\033[36mОтключение запроса пароля.\033[0m"
echo 'polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});' > /mnt/etc/polkit-1/rules.d/49-nopasswd_global.rules
#
#Создание конфига рабочего стола №1.
echo -e "\033[36mСоздание конфига рабочего стола №1.\033[0m"
echo '{
    "border": "normal",
    "floating": "auto_off",
    "layout": "splitv",
    "percent": 0.5,
    "type": "con",
    "nodes": [
        {
            "border": "normal",
            "current_border_width": 2,
            "floating": "auto_off",
            "percent": 0.7,
            "swallows": [
               {
                "class": "^kate$",
                "window_role": "^MainWindow\\#1$"
               }
            ],
            "type": "con"
        },
        {
            "border": "normal",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 0.3,
            "type": "con",
            "nodes": [
                {
                    "border": "normal",
                    "current_border_width": 2,
                    "floating": "user_off",
                    "percent": 0.5,
                    "swallows": [
                       {
                        "title": "^'"$username"'\\@'"$hostname"'\\:\\~$"
                       }
                    ],
                    "type": "con"
                },
                {
                    "border": "normal",
                    "current_border_width": 2,
                    "floating": "user_off",
                    "percent": 0.5,
                    "swallows": [
                       {
                        "title": "^'"$username"'\\@'"$hostname"'\\:\\~$"
                       }
                    ],
                    "type": "con"
                }
            ]
        }
    ]
}

{
    "border": "normal",
    "floating": "auto_off",
    "layout": "splitv",
    "percent": 0.5,
    "type": "con",
    "nodes": [
        {
            "border": "normal",
            "current_border_width": 2,
            "floating": "auto_off",
            "percent": 0.5,
            "swallows": [
               {
                "class": "^dolphin$",
                "window_role": "^Dolphin\\#1$"
               }
            ],
            "type": "con"
        },
        {
            "border": "none",
            "current_border_width": 2,
            "floating": "auto_off",
            "name": "Telegram",
            "percent": 0.5,
            "swallows": [
               {
                "class": "^TelegramDesktop$"
               }
            ],
            "type": "con"
        }
    ]
}' > /mnt/home/"$username"/.config/i3/workspace_1.json
#
#Создание скрипта загрузки рабочего стола №1.
echo -e "\033[36mСоздание скрипта загрузки рабочего стола №1.\033[0m"
echo '#!/bin/sh
i3-msg "workspace 1; append_layout ~/.config/i3/workspace_1.json"
(kate &)
(xterm &)
(xterm &)
(dolphin &)
(telegram-desktop &)' > /mnt/home/"$username"/.config/i3/workspace.sh
#
#Создание подсказки.
echo -e "\033[36mСоздание подсказки.\033[0m"
echo '#
Win+Enter -- Запустить терминал.
Win+D -- Запуск dmenu (программа запуска).
Win+F1 -- Запустить firefox.
Win+Shift+Q -- Закрыть окно в фокусе.
Print Screen -- Снимок экрана.
ПКМ на нижней панели -- Снимок экрана.
#
ЛКМ на кнопке 🛠 -- Обновить ArchLinux.
ScrollUp на кнопке 🛠 -- Удалить кэш pacman.
ScrollDown на кнопке 🛠 -- Удалить пакеты сироты.
#
ScrollUp на кнопке 🛈 -- Открыть страницу Arch_wiki.
ScrollDown на кнопке 🛈 -- Открыть XTerm.
#
ЛКМ на кнопке 🚀 -- Отключить визуальные эффекты.
ScrollUp на кнопке 🚀 -- Включить визуальные эффекты.
ScrollDown на кнопке 🚀 -- Открыть sweeper.
#
ЛКМ на кнопке ⏻ -- Выключить ПК.
ScrollUp на кнопке ⏻ -- Перезагрузить ПК.
ScrollDown на кнопке ⏻ -- Выйти из системы.
#
ScrollUp на заголовке -- Развернуть окно во весь экран.
ScrollDown на заголовке -- Закрывает окно.
ПКМ на заголовке -- Делает окно плавающим.
СКМ на заголовке -- Сворачивает окно в черновик.
#
Win+Left -- Фокус на левое окно.
Win+Down -- Фокус на нижнее окно.
Win+Up -- Фокус на верхнее окно.
Win+Right -- Фокус на правое окно.
#
Win+Shift+Left -- Переместить окно влево.
Win+Shift+Down -- Переместить окно вниз.
Win+Shift+Up -- Переместить окно вверх.
Win+Shift+Right -- Переместить окно вправо.
#
Win+H -- Следующее открытое окно разделит экран по горизонтали.
Win+V -- Следующее открытое окно разделит экран по вертикали.
Win+F -- Развернуть окно во весь экран.
Win+S Win+W Win+E -- Делаем из окон вкладки.
#
Win+1..0 -- Переключение между рабочими столами.
Win+Shift+1..0 -- Переместить сфокусированное окно на заданный рабочий стол.
#
Win+Shift+R -- Перезапустить i3.
Win+Shift+E -- Выход из i3 (выходит из сеанса X).
#
Win+R -- Войти/Выйти в режим изменения размеров окон.
Left -- Сдвинуть границу влево.
Down -- Сдвинуть границу вниз.
Up -- Сдвинуть границу вверх.
Right -- Сдвинуть границу вправо.
#
Win+Shift+Minus -- Сделать текущее окно черновиком/блокнотом.
Win+Minus -- Показать первое окно черновика/блокнота.
#
Win+Alt-left+1 -- Восстановление рабочего стола №1.
#' > /mnt/help.txt
#
#Создание директории и конфига gtk.
echo -e "\033[36mСоздание конфига gtk.\033[0m"
mkdir -p /mnt/home/$username/.config/gtk-3.0/
mkdir -p /mnt/home/$username/.config/gtk-4.0/
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=Adwaita
gtk-font-name=Fantasque Sans Mono Bold Italic '"$font"'
gtk-icon-theme-name=ePapirus-Dark
gtk-theme-name=Adwaita-dark' > /mnt/home/"$username"/.config/gtk-3.0/settings.ini
cp /mnt/home/"$username"/.config/gtk-3.0/settings.ini /mnt/home/"$username"/.config/gtk-4.0/settings.ini
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=Adwaita
gtk-font-name="Fantasque Sans Mono Bold Italic '"$font"'"
gtk-icon-theme-name="ePapirus-Dark"
gtk-theme-name="Adwaita-dark"' > /mnt/home/"$username"/.config/gtkrc-2.0
echo 'ENABLE_VKBASALT=1
GTK_USE_PORTAL=1' >> /etc/environment
#
#Создание директории и конфига lxqt-panel.
echo -e "\033[36mСоздание конфига lxqt-panel.\033[0m"
mkdir -p /mnt/home/"$username"/.config/lxqt
echo '[General]
__userfile__=true
iconTheme=ePapirus-Dark
[customcommand]
alignment=Right
click=xterm -e /bin/bash -l -c \"sudo pacman -Suy --noconfirm\"
command=echo \xd83d\xdee0
maxWidth=500
repeat=false
type=customcommand
wheelDown=xterm -e /bin/bash -l -c \"sudo pacman -Rsn $(pacman -Qdtq) --noconfirm\"
wheelUp=xterm -e /bin/bash -l -c \"sudo pacman -Sc --noconfirm\"
[customcommand2]
alignment=Right
click=kate /help.txt
command=echo \xd83d\xdec8
type=customcommand
wheelDown=xterm
wheelUp=firefox https://wiki.archlinux.org/title/Main_page
[customcommand3]
alignment=Right
click=killall picom conky
command=echo \xd83d\xde80
type=customcommand
wheelDown=sweeper
wheelUp="/bin/bash -c \"picom -b; conky\""
[customcommand4]
alignment=Right
click=poweroff
command=echo \x23fb
type=customcommand
wheelDown=i3-msg exit
wheelUp=reboot
[kbindicator]
alignment=Right
keeper_type=application
show_caps_lock=true
show_layout=true
show_num_lock=true
show_scroll_lock=true
type=kbindicator
[mainmenu]
alignment=Left
filterClear=true
icon=/usr/share/icons/Papirus-Dark/48x48/apps/distributor-logo-archlinux.svg
menu_file=/etc/xdg/menus/applications.menu
ownIcon=true
showText=false
type=mainmenu
[panel1]
alignment=0
animation-duration=0
background-color=@Variant(\0\0\0\x43\x1\xff\xff++++++\0\0)
desktop=0
font-color=@Variant(\0\0\0\x43\0\xff\xff\0\0\0\0\0\0\0\0)
hidable=false
hide-on-overlap=false
iconSize='"$(($font*4))"'
lineCount=1
lockPanel=false
opacity=50
panelSize='"$(($font*4))"'
plugins=mainmenu, spacer, quicklaunch, kbindicator, volume, customcommand, customcommand2, customcommand3, customcommand4
position=Top
reserve-space=true
show-delay=0
visible-margin=true
width=100
width-percent=true
[quicklaunch]
alignment=Left
type=quicklaunch
[spacer]
alignment=Left
type=spacer
[volume]
alignment=Right
audioEngine=PulseAudio
type=volume' > /mnt/home/"$username"/.config/lxqt/panel.conf
#
#Создание конфига kdeglobals.
echo -e "\033[36mСоздание конфига kdeglobals.\033[0m"
echo '[Colors:Button]
BackgroundNormal=53,53,53
BackgroundAlternate=50,50,50
ForegroundNormal=238,238,238
ForegroundInactive=178,178,178
[Colors:Tooltip]
BackgroundNormal=53,53,53
BackgroundAlternate=50,50,50
ForegroundNormal=238,238,238
ForegroundInactive=178,178,178
[Colors:View]
BackgroundNormal=43,43,43
BackgroundAlternate=50,50,50
ForegroundNormal=238,238,238
ForegroundInactive=178,178,178
[Colors:Window]
BackgroundNormal=56,56,56
BackgroundAlternate=50,50,50
ForegroundNormal=238,238,238
ForegroundInactive=178,178,178' > /mnt/home/"$username"/.config/kdeglobals
#
#Установка шрифтов.
echo -e "\033[36mУстановка шрифтов.\033[0m"
mkdir -p /mnt/usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Emoji.zip https://fonts.google.com/download?family=Noto%20Emoji
arch-chroot /mnt unzip -o /usr/share/fonts/google/Emoji.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Symbols.zip https://fonts.google.com/download?family=Noto%20Sans%20Symbols
arch-chroot /mnt unzip -o /usr/share/fonts/google/Symbols.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Symbols2.zip https://fonts.google.com/download?family=Noto%20Sans%20Symbols%202
arch-chroot /mnt unzip -o /usr/share/fonts/google/Symbols2.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Duployan.zip https://fonts.google.com/download?family=Noto%20Sans%20Duployan
arch-chroot /mnt unzip -o /usr/share/fonts/google/Duployan.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Music.zip https://fonts.google.com/download?family=Noto%20Music
arch-chroot /mnt unzip -o /usr/share/fonts/google/Music.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Math.zip https://fonts.google.com/download?family=Noto%20Sans%20Math
arch-chroot /mnt unzip -o /usr/share/fonts/google/Math.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Sans.zip https://fonts.google.com/download?family=Noto%20Sans
arch-chroot /mnt unzip -o /usr/share/fonts/google/Sans.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Arabic.zip https://fonts.google.com/download?family=Noto%20Sans%20Arabic
arch-chroot /mnt unzip -o /usr/share/fonts/google/Arabic.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Serif.zip https://fonts.google.com/download?family=Noto%20Serif
arch-chroot /mnt unzip -o /usr/share/fonts/google/Serif.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/TC.zip https://fonts.google.com/download?family=Noto%20Serif%20TC
arch-chroot /mnt unzip -o /usr/share/fonts/google/TC.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Armenian.zip https://fonts.google.com/download?family=Noto%20Serif%20Armenian
arch-chroot /mnt unzip -o /usr/share/fonts/google/Armenian.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Gurmukhi.zip https://fonts.google.com/download?family=Noto%20Serif%20Gurmukhi
arch-chroot /mnt unzip -o /usr/share/fonts/google/Gurmukhi.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Gujarati.zip https://fonts.google.com/download?family=Noto%20Serif%20Gujarati
arch-chroot /mnt unzip -o /usr/share/fonts/google/Gujarati.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Tamil.zip https://fonts.google.com/download?family=Noto%20Serif%20Tamil
arch-chroot /mnt unzip -o /usr/share/fonts/google/Tamil.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Hebrew.zip https://fonts.google.com/download?family=Noto%20Serif%20Hebrew
arch-chroot /mnt unzip -o /usr/share/fonts/google/Hebrew.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/JP.zip https://fonts.google.com/download?family=Noto%20Serif%20JP
arch-chroot /mnt unzip -o /usr/share/fonts/google/JP.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/KR.zip https://fonts.google.com/download?family=Noto%20Serif%20KR
arch-chroot /mnt unzip -o /usr/share/fonts/google/KR.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Khmer.zip https://fonts.google.com/download?family=Noto%20Serif%20Khmer
arch-chroot /mnt unzip -o /usr/share/fonts/google/Khmer.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Georgian.zip https://fonts.google.com/download?family=Noto%20Serif%20Georgian
arch-chroot /mnt unzip -o /usr/share/fonts/google/Georgian.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Kannada.zip https://fonts.google.com/download?family=Noto%20Serif%20Kannada
arch-chroot /mnt unzip -o /usr/share/fonts/google/Kannada.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Thai.zip https://fonts.google.com/download?family=Noto%20Serif%20Thai
arch-chroot /mnt unzip -o /usr/share/fonts/google/Thai.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Devanagari.zip https://fonts.google.com/download?family=Noto%20Serif%20Devanagari
arch-chroot /mnt unzip -o /usr/share/fonts/google/Devanagari.zip -d /usr/share/fonts/google
curl -o /mnt/usr/share/fonts/google/Bengali.zip https://fonts.google.com/download?family=Noto%20Serif%20Bengali
arch-chroot /mnt unzip -o /usr/share/fonts/google/Bengali.zip -d /usr/share/fonts/google
rm /mnt/usr/share/fonts/google/*.zip
rm /mnt/usr/share/fonts/google/*.txt
#
#Передача интернет настроек в установленную систему.
echo -e "\033[36mПередача интернет настроек в установленную систему.\033[0m"
if [ -z "$namewifi" ]; then arch-chroot /mnt ip link set "$netdev" up
    else
        arch-chroot /mnt pacman --color always -Sy iwd --noconfirm
        arch-chroot /mnt systemctl enable iwd
        arch-chroot /mnt ip link set "$netdev" up
        mkdir -p /mnt/var/lib/iwd
        cp /var/lib/iwd/"$namewifi".psk /mnt/var/lib/iwd/"$namewifi".psk
fi
#Определяем, есть ли ssd.
echo -e "\033[36mОпределяем, есть ли ssd.\033[0m"
massd=($(lsblk -dno rota))
for (( j=0, i=1; i<="${#massd[*]}"; i++, j++ ))
    do
        if [ "${massd[$j]}" = 0 ];
            then
                fstrim -v -a
                arch-chroot /mnt systemctl enable fstrim.timer
            break
        fi
    done
#
#Установка помощника yay для работы с AUR.
echo -e "\033[36mУстановка помощника yay для работы с AUR.\033[0m"
arch-chroot /mnt/ sudo -u "$username" sh -c 'cd /home/'"$username"'/
git clone https://aur.archlinux.org/yay.git
cd /home/'"$username"'/yay
BUILDDIR=/tmp/makepkg makepkg -i --noconfirm'
rm -Rf /mnt/home/"$username"/yay
#
#Установка программ из AUR.
echo -e "\033[36mУстановка программ из AUR.\033[0m"
arch-chroot /mnt/ sudo -u "$username" yay -S hardinfo debtap libreoffice-extension-languagetool cups-xerox-b2xx minq-ananicy-git auto-cpufreq vkbasalt --noconfirm
#
#Автозапуск служб.
echo -e "\033[36mАвтозапуск служб.\033[0m"
arch-chroot /mnt systemctl disable dbus
arch-chroot /mnt systemctl enable fancontrol NetworkManager saned.socket cups.socket cups-browsed reflector.timer xdm-archlinux dhcpcd avahi-daemon ananicy haveged dbus-broker auto-cpufreq smartd
arch-chroot /mnt systemctl --user --global enable redshift-gtk
#
#Настройка звука.
echo -e "\033[36mНастройка звука.\033[0m"
arch-chroot /mnt sed -i 's/; resample-method = speex-float-1/resample-method = src-sinc-best-quality/' /etc/pulse/daemon.conf
#
#Создание общего конфига obs-studio.
echo -e "\033[36mСоздание общего конфига obs-studio.\033[0m"
mkdir -p /mnt/home/"$username"/.config/obs-studio/
echo -e "[BasicWindow]
SysTrayWhenStarted=true
SysTrayMinimizeToTray=true" > /mnt/home/"$username"/.config/obs-studio/global.ini
#
#Создание скрипта, который после перезагрузки продолжит установку.
echo -e "\033[36mСоздание скрипта, который после перезагрузки продолжит установку.\033[0m"
echo -e '#!/bin/bash
ls ~/.mozilla/firefox/*.default-release
echo -e \047user_pref("layout.css.devPixelsPerPx", "'"$fox"'");
user_pref("accessibility.typeaheadfind", true);
user_pref("intl.regional_prefs.use_os_locales", true);
user_pref("widget.gtk.overlay-scrollbars.enabled", false);
user_pref("browser.startup.page", 3);
user_pref("browser.download.useDownloadDir", false);\047 > $_/user.js
if [ -n "$(clinfo -l)" ];
    then sed -i \047s/#TechnicalSymbol //\047 ~/.config/picom.conf
    else sed -i \047/#TechnicalSymbol /d\047 ~/.config/picom.conf
fi
soundmass=($(pacmd list-sinks | grep -i name: | awk \047{print $2}\047))
for (( j=0, i=1; i<="${#soundmass[*]}"; i++, j++ ))
            do
amixer -c "$j" sset Master unmute
amixer -c "$j" sset Speaker unmute
amixer -c "$j" sset Headphone unmute
amixer -c "$j" sset "Auto-Mute Mode" Disabled
            done
alsactl store
sed -i \047/#TechnicalString/d\047 ~/.config/i3/config
gsettings set org.gnome.desktop.interface icon-theme ePapirus-Dark
gsettings set org.gnome.desktop.interface font-name \047Fantasque Sans Mono, '"$font"'\047
gsettings set org.gnome.desktop.interface document-font-name \047Fantasque Sans Mono Bold Italic '"$font"'\047
gsettings set org.gnome.desktop.interface monospace-font-name \047Fantasque Sans Mono '"$font"'\047
gsettings set org.gnome.desktop.wm.preferences titlebar-font \047Fantasque Sans Mono Bold '"$font"'\047
gsettings set org.gnome.libgnomekbd.indicator font-size '"$font"'
gsettings set org.gnome.meld custom-font \047monospace, '"$font"'\047
WINEARCH=win32 winetricks d3dx9 vkd3d vcrun6 mfc140 dxvk dotnet48 allcodecs
rm ~/archinstall.sh' > /mnt/home/"$username"/archinstall.sh
#
#Делаем xinitrc и archinstall.sh исполняемыми.
chmod +x /mnt/home/"$username"/.xinitrc /mnt/home/"$username"/archinstall.sh /mnt/home/"$username"/.config/i3/workspace.sh
#
#Передача прав созданному пользователю.
echo -e "\033[36mПередача прав созданному пользователю.\033[0m"
arch-chroot /mnt chown -R "$username" /home/"$username"/
#
#Установка завершена, после перезагрузки вас встретит настроенная и готовая к работе ОС.
echo -e "\033[36mУстановка завершена, после перезагрузки вас встретит настроенная и готовая к работе ОС.\033[0m"
while [[ 0 -ne $tic ]]; do
    echo -e "\033[31m...\033[36m$tic\033[31m...\033[0m"
    sleep 1
    tic=$(($tic-1))
done
#umount -R /mnt
#reboot
