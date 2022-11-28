#!/bin/bash
#
#Установим язык и шрифт консоли.
loadkeys ru
setfont ter-v18n
#
#Сброс переменных и размонтирование разделов, на случай повторного запуска скрипта.
echo -e "\033[31mСброс переменных и размонтирование разделов, на случай повторного запуска скрипта.\033[32m"
swapoff -a
umount -R /mnt
#
#Определяем процессор.
echo -e "\033[31mОпределяем процессор.\033[32m"
if [ -n "$(lscpu | grep -i amd)" ]; then microcode="\ninitrd /amd-ucode.img"
elif [ -n "$(lscpu | grep -i intel)" ]; then microcode="\ninitrd /intel-ucode.img"
fi
echo -e "Процессор:"$(lscpu | grep -i "model name")""
#
#Определяем сетевое устройство.
echo -e "\033[31mОпределяем сетевое устройство.\033[32m"
if [ -n "$(iwctl device list | awk '{print $2}' | grep wl | head -n 1)" ];
    then
        echo -e "\033[41m\033[30mОбнаружен wifi модуль, если основное подключение к интернету планируется через wifi введите имя сети, если через провод нажмите Enter:\033[0m\033[36m";read -p ">" namewifi
        netdev="$(iwctl device list | awk '{print $2}' | grep wl | head -n 1)"
fi
if [ -z "$namewifi" ];
    then
        netdev="$(ip -br link show | grep -vEi "unknown|down" | awk '{print $1}' | xargs)"
    else
        echo -e "\033[41m\033[30mПароль wifi:\033[0m\033[36m";read -p ">" passwifi
        iwctl --passphrase "$passwifi" station "$netdev" connect "$namewifi"
fi
echo -e "\033[31mСетевое устройство:"$netdev"\033[32m"
#
#Определяем часовой пояс.
echo -e "\033[31mОпределяем часовой пояс.\033[32m"
timedatectl set-timezone "$(curl https://ipapi.co/timezone)"
echo -e "\033[31mЧасовой пояс:"$(curl https://ipapi.co/timezone)"\033[32m"
#
#Определяем физический диск на который будет установлена ОС.
echo -e "\033[31mОпределяем физический диск на который будет установлена ОС.\033[32m"
massdisks=($(lsblk -fno +TRAN | grep -ivE "├─|└─|rom|usb|/|SWAP" | awk '{print $1}'))
if [ "${#massdisks[*]}" = 1 ]; then sysdisk="${massdisks[0]}"
elif [ "${#massdisks[*]}" = 0 ];
    then
        echo -e "\033[41m\033[30mДоступных дисков не обнаружено!\033[32m"
        exit 0
    else
        echo -e "\033[41m\033[30mВведите метку диска (выделено красным) на который будет установлена ОС:\033[0m"
        for (( j=0, i=1; i<="${#massdisks[*]}"; i++, j++ ))
            do
                grepmassdisks+="${massdisks[$j]}|"
            done
        lsscsi -s | grep -viE "rom|usb" | grep --color -iE "$grepmassdisks"
        echo -e "\033[36m"
        read -p ">" sysdisk
fi
echo -e "\033[31mФизический диск на который будет установлена ОС:"$sysdisk"\033[32m"
#
#Определяем есть ли nvme контролер системного диска.
echo -e "\033[31mОпределяем есть ли nvme контролер системного диска.\033[32m"
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
echo -e "\033[31mСбор данных пользователя.\033[32m"
echo "
"
echo -e "\033[41m\033[30mВведите имя компьютера:\033[0m\033[36m";read -p ">" hostname
echo "
"
echo -e "\033[41m\033[30mВведите имя пользователя:\033[0m\033[36m";read -p ">" username
echo "
"
echo -e "\033[41m\033[30mВведите пароль для "$username":\033[0m\033[36m";read -p ">" passuser
echo "
"
echo -e "\033[41m\033[30mВведите пароль для root:\033[0m\033[36m";read -p ">" passroot
echo -e "\033[31mВыберите разрешение монитора:\033[32m"
PS3="$(echo -e "\033[41m\033[30mПункт №:\033[0m\033[36m
>")"
select resolution in "~480p." "~720p-1080p." "~4K."
do
    case "$resolution" in
        "~480p.")
            font=6
            gap=20
            xterm="700 350"
            break
            ;;
        "~720p-1080p.")
            font=8
            gap=40
            xterm="1000 500"
            break
            ;;
        "~4K.")
            font=10
            gap=60
            xterm="2000 1000"
            break
            ;;
        *) echo -e "\033[31mЧто значит - "$REPLY"? До трёх посчитать не можешь и Arch Linux ставишь?\033[36m";;
    esac
done
#
#Разметка системного диска.
echo -e "\033[31mРазметка системного диска.\033[32m"
if [ -z "$(efibootmgr | grep Boot)" ];
    then
        echo -e "\033[31mLegacy boot.\033[32m"
fdisk /dev/"$sysdisk"<<EOF
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
        echo -e "\033[31mUEFI boot.\033[32m"
fdisk /dev/"$sysdisk"<<EOF
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
#Установка ОС.
echo -e "\033[31mУстановка ОС.\033[32m"
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware nano dhcpcd
#
#Установка часового пояса.
echo -e "\033[31mУстановка часового пояса.\033[32m"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$(curl https://ipapi.co/timezone)" /etc/localtime
echo -e "\033[32m"
arch-chroot /mnt hwclock --systohc
#
#Настройка локали.
echo -e "\033[31mНастройка локали.\033[32m"
arch-chroot /mnt sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
arch-chroot /mnt sed -i 's/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
echo -e "LANG=\"ru_RU.UTF-8\"" > /mnt/etc/locale.conf
echo -e "KEYMAP=ru\nFONT=ter-v18n\nUSECOLOR=yes" > /mnt/etc/vconsole.conf
echo -e "\033[32m"
arch-chroot /mnt locale-gen
#
#Имя ПК.
echo "$hostname" > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 "$hostname".localdomain "$hostname"" > /mnt/etc/hosts
#
#ROOT пароль.
echo -e "\033[32m"
arch-chroot /mnt passwd<<EOF
$passroot
$passroot
EOF
#
#Создание пользователя.
echo -e "\033[31mСоздание пользователя.\033[32m"
arch-chroot /mnt useradd -m -g users -G wheel -s /bin/bash "$username"
#
#Пароль пользователя.
echo -e "\033[32m"
arch-chroot /mnt passwd "$username"<<EOF
$passuser
$passuser
EOF
#
#Убираем sudo пароль для пользователя.
echo ""$username" ALL=(ALL:ALL) NOPASSWD: ALL" >> /mnt/etc/sudoers
#
#Установим загрузчик.
echo -e "\033[31mУстановка загрузчика.\033[32m"
if [ -z "$(efibootmgr | grep Boot)" ];
    then
        arch-chroot /mnt pacman -Sy grub --noconfirm
        arch-chroot /mnt grub-install /dev/"$sysdisk"
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    else
        arch-chroot /mnt pacman -Sy efibootmgr --noconfirm
        arch-chroot /mnt bootctl install
        echo -e "default arch\ntimeout 2\neditor 0" > /mnt/boot/loader/loader.conf
        echo -e "title  Arch Linux Virtual\nlinux  /vmlinuz-linux-zen"$microcode"\ninitrd  /initramfs-linux-zen.img\noptions root=/dev/"$sysdisk""$p3" rw" > /mnt/boot/loader/entries/arch.conf
fi
#
#Установим микроинструкции для процессора.
echo -e "\033[31mУстановка микроинструкций для процессора.\033[32m"
if [ "$microcode" = "\ninitrd /amd-ucode.img" ]; then arch-chroot /mnt pacman -Sy amd-ucode --noconfirm
elif [ "$microcode" = "\ninitrd /intel-ucode.img" ]; then arch-chroot /mnt pacman -Sy intel-ucode iucode-tool --noconfirm
fi
#
#Настройка установщика.
echo -e "\033[31mНастройка установщика.\033[32m"
arch-chroot /mnt sed -i "s/#Color/Color/" /etc/pacman.conf
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
#
#Настройка sysrq.
echo -e "\033[31mНастройка sysrq.\033[32m"
echo "kernel.sysrq=1" > /mnt/etc/sysctl.d/99-sysctl.conf
#
#Установим и настроим программу для фильтрования зеркал.
echo -e "\033[31mУстановка и настройка программы для фильтрования зеркал.\033[32m"
arch-chroot /mnt pacman -Sy reflector --noconfirm
echo -e "--country "$(curl https://ipapi.co/country_name/)"" >> /mnt/etc/xdg/reflector/reflector.conf
#
#Установим видеодрайвер.
echo -e "\033[31mУстановка видеодрайвера.\033[32m"
if [ -n "$(lspci | grep -i vga | grep -i amd)" ]; then arch-chroot /mnt pacman -Sy vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i ati)" ]; then arch-chroot /mnt pacman -Sy xf86-video-ati libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then arch-chroot /mnt pacman -Sy nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia opencv-cuda nvtop cuda --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i intel)" ]; then arch-chroot /mnt pacman -Sy xf86-video-intel vulkan-intel --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i 'vmware svga')" ]; then arch-chroot /mnt pacman -Sy virtualbox-guest-utils virtualbox-guest-iso virtualbox-guest-utils-nox --noconfirm
elif [ -n "$(lspci | grep -i vga | grep -i virtualbox )" ]; then arch-chroot /mnt pacman -Sy virtualbox-guest-utils virtualbox-guest-iso virtualbox-guest-utils-nox --noconfirm
fi
#
#Установка программ.
echo -e "\033[31mУстановка программ.\033[32m"
arch-chroot /mnt pacman -Sy xorg i3-gaps xorg-xinit xterm dmenu xdm-archlinux i3status git firefox numlockx ark mc htop conky polkit dolphin ntfs-3g dosfstools qt5ct lxappearance-gtk3 papirus-icon-theme picom redshift tint2 grc flameshot xscreensaver notification-daemon adwaita-qt5 gnome-themes-extra alsa-utils alsa-plugins lib32-alsa-plugins alsa-firmware alsa-card-profiles pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol freetype2 noto-fonts-extra noto-fonts-cjk ttf-font-awesome awesome-terminal-fonts cheese kate wine winetricks mesa lib32-mesa go wireless_tools avahi libnotify thunar --noconfirm
arch-chroot /mnt pacman -Ss geoclue2
#
#Поиск не смонтированных разделов.
echo -e "\033[31mПоиск не смонтированных разделов.\033[32m"
massparts=($(lsblk -sno +TRAN | grep -ivE "└─|"$sysdisk"|rom|usb|/|SWAP" | awk '{print $1}'))
for (( j=0, i=1; i<="${#massparts[*]}"; i++, j++ ))
    do
        if [ -z "$(lsblk -no LABEL /dev/"${massparts[$j]}")" ];
            then
                arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/"${massparts[$j]}"
masslabel+='
${color #f92b2b}/home/'"$username"'/'"${massparts[$j]}"'${hr 3}
${color #b2b2b2}Объём:$alignr${fs_size /home/'"$username"'/'"${massparts[$j]}"'} / ${fs_used /home/'"$username"'/'"${massparts[$j]}"'} / $color${fs_free /home/'"$username"'/'"${massparts[$j]}"'}
(${fs_type /home/'"$username"'/'"${massparts[$j]}"'})${fs_bar 4 /home/'"$username"'/'"${massparts[$j]}"'}'
            else
                arch-chroot /mnt mount --mkdir /dev/"${massparts[$j]}" /home/"$username"/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
masslabel+='
${color #f92b2b}/home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'${hr 3}
${color #b2b2b2}Объём:$alignr${fs_size /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${fs_used /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / $color${fs_free /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}
(${fs_type /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'})${fs_bar 4 /home/'"$username"'/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}'
        fi
    done
#
#Копирование файла автоматического монтирования разделов.
echo -e "\033[31mПеренос genfstab.\033[32m"
genfstab -pU /mnt >> /mnt/etc/fstab
#
#Создание общего конфига загрузки оконного менеджера.
echo -e "\033[31mСоздание xinit.\033[32m"
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
exec i3 #Автозапуск i3.' > /mnt/etc/X11/xinit/xinitrc
#
#Создание общего конфига клавиатуры.
echo -e "\033[31mСоздание 00-keyboard.\033[32m"
echo 'Section "InputClass"
Identifier "system-keyboard"
MatchIsKeyboard "on"
Option "XkbLayout" "us,ru"
Option "XkbOptions" "grp:alt_shift_toggle,terminate:ctrl_alt_bksp"
EndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
#
#Создание общего конфига сканера.
echo -e "\033[31mСоздание sane.d.\033[32m"
mkdir -p /mnt/etc/sane.d
echo -e "localhost\n192.168.0.0/24" >> /mnt/etc/sane.d/net.conf
#
echo -e "\033[31mФормируется конфиг conky.\033[32m"
#
#Температура ядер процессора.
core=($(arch-chroot /mnt sensors | grep Core | awk '{print $1}' | xargs))
for (( i=0, j=1; j<="${#core[*]}"; i++, j++ ))
    do
        coreconf+="
\$alignr\${execi 10 sensors | grep \"Core $i:\" | awk '{print \$1, \$2, \$3}' }"
    done
#
#Параметры для видеокарт nvidia.
if [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then
    nvidiac='
${color #f92b2b}GPU${hr 3}$color
${color #b2b2b2}Частота ГП:$color$alignr${nvidia gpufreq} Mhz
${color #b2b2b2}Видео ОЗУ:$color$alignr${nvidia mem} / ${nvidia memmax} MiB
${color #b2b2b2}Температура ГП:$color$alignr${nvidia temp} °C'
fi
#
#Создание директории и конфига.
mkdir -p /mnt/home/"$username"/.config/conky
echo 'conky.config = { --Внешний вид.
alignment = "top_right", --Располжение виджета.
border_inner_margin = '"$font"', --Отступ от внутренних границ.
border_outer_margin = '"$font"', --Отступ от края окна.
border_width = 1, --Толщина рамки.
cpu_avg_samples = 2, --Усреднение значений нагрузки.
default_color = "#2bf92b", --Цвет по умолчанию.
default_outline_color = "#2bf92b", --Цвет рамки по умолчанию.
double_buffer = true, --Включение двойной буферизации.
draw_shades = false, --Оттенки.
draw_borders = true, --Включение границ.
font = "Noto Sans Mono:size='"$font"'", --Шрифт и размер шрифта.
gap_y = '"$(($gap/2+$gap))"', --Отступ сверху.
gap_x = 40, --Отступ от края.
own_window = true, --Собственное окно.
own_window_class = "Conky", --Класс окна.
own_window_type = "override", --Тип окна (возможные варианты: "normal", "desktop", "ock", "panel", "override" выбираем в зависимости от оконного менеджера и личных предпочтений).
own_window_hints = "undecorated, skip_taskbar", --Задаем эфекты отображения окна.
own_window_argb_visual = true, --Прозрачность окна.
own_window_argb_value = 200, --Уровень прозрачности.
use_xft = true, } --Использование шрифтов X сервера.
conky.text = [[ #Наполнение виджета.
#Блок "Время".
#Часы.
${font :size='"$(($font*4))"'}$alignc${color #f92b2b}$alignc${time %H:%M}$font$color
#Дата.
${font :size='"$font"'}$alignc${color #b2b2b2}${time %d %b %Y} (${time %a})$font$color
#Блок "Система".
#Разделитель.
${color #f92b2b}SYS${hr 3}$color
#Ядро.
${color #b2b2b2}Ядро:$color$alignr$kernel
#Время в сети.
${color #b2b2b2}Время в сети:$color$alignr$uptime
#Блок "ЦП".
#Разделитель.
${color #f92b2b}CPU${hr 3}$color
#Нагрузка ЦП.
${color #b2b2b2}Нагрузка ЦП:$color$alignr$cpu %
#Частота ЦП.
${color #b2b2b2}Частота ЦП:$color$alignr$freq MHz
${color #b2b2b2}Температура ядер ЦП:
#Температура ядер ЦП. '"${coreconf[@]}"'
#Блок "Видеокарта Nvidia". '"$nvidiac"'
#Блок "ОЗУ".
#Разделитель.
${color #f92b2b}RAM${hr 3}$color
#ОЗУ.
${color #b2b2b2}ОЗУ:$color$alignr$mem / $memeasyfree / $memmax
#Полоса загрузки ОЗУ.
$memperc%${membar 4}
#Блок "Подкачка".
#Разделитель.
${color #f92b2b}SWAP${hr 3}$color
#Задействовано Подкачки.
${color #b2b2b2}Задействовано:$color$alignr$swap / $swapmax
#Полоса загрузки Подкачки.
$swapperc%${swapbar 4}
#Блок "Сеть".
#Разделитель.
${color #f92b2b}NET${hr 3}$color
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
#Блок "Диск1".
#Разделитель.
${color #f92b2b}/home${hr 3}$color
#Общее/Занято/Свободно.
${color #b2b2b2}Объём:$alignr${fs_size /home} / ${fs_used /home} / $color${fs_free /home}
#Полоса загрузки.
$color(${fs_type /home})${fs_bar 4 /home}
#Блок "Диски".'"${masslabel[@]}"'
]]' > /mnt/home/"$username"/.config/conky/conky.conf
#
#Создание bash_profile.
echo -e "\033[31mСоздание bash_profile.\033[32m"
echo '[[ -f ~/.profile ]] && . ~/.profile' > /mnt/home/"$username"/.bash_profile
#
#Создание bashrc.
echo -e "\033[31mСоздание bashrc.\033[32m"
echo '[[ $- != *i* ]] && return #Определяем интерактивность шелла.
#Автоматическая прозрачность xterm.
[ -n "$XTERM_VERSION" ] && transset-df --id "$WINDOWID" >/dev/null
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
PS1="\[\033[43m\]\[\033[2;34m\]\A\[\033[0m\]\[\033[44m\]\[\033[3;33m\]\u@\h \W/\[\033[0m\]\[\033[5;91m\]\$: \[\033[0m\]"
#\[\033[43m\] - тёмно-жёлтый цвет фона.
#\[\033[2;34m\] - 2 - более темный цвет, 34 - тёмно-синий цвет.
#\A Текущее время в 24-часовом формате.
#\[\033[0m\] - Конец изменениям.
#\[\033[44m\] - тёмно-синий цвет фона.
#\[\033[3;33m\] - 3 - курсив, 33 - тёмно-жёлтый цвет.
#\u@\h \W ИмяПользователя@ИмяХоста ТекущийОтносительныйПуть.
#\[\033[0m\] - Конец изменениям.
#\[\033[5;91m\] - 5 - моргание, 91 - красный цвет.
#\$: Символ приглашения (# для root, $ для обычных пользователей).
#\[\033[0m\] - Конец изменениям.
#Удаляем повторяющиеся записи и записи начинающиеся с пробела (например команды в mc) в .bash_history.
export HISTCONTROL="ignoreboth"
export COLORTERM=truecolor #Включаем все 16 миллионов цветов в эмуляторе терминала.' > /mnt/home/"$username"/.bashrc
#
#Создание profile.
echo -e "\033[31mСоздание profile.\033[32m"
echo 'setleds -D +num #Включенный по умолчанию NumLock.
[[ -f ~/.bashrc ]] && . ~/.bashrc #Указание на bashrc.
export QT_QPA_PLATFORMTHEME="qt5ct" #Изменение внешнего вида приложений использующих qt.' > /mnt/home/"$username"/.profile
#
#Создание конфига сервера уведомлений.
echo -e "\033[31mСоздание конфига сервера уведомлений.\033[32m"
echo '[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/notification-daemon-1.0/notification-daemon' > /mnt/usr/share/dbus-1/services/org.freedesktop.Notifications.service
#
#Создание конфига picom.
echo -e "\033[31mСоздание конфига picom.\033[32m"
echo -e "# Прозрачность неактивных окон (0,1–1,0).
inactive-opacity = 0.9;
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
wintypes:
{
# Отключить прозрачность выпадающего меню.
dropdown_menu = { opacity = false; };
#
# Отключить прозрачность всплывающего меню.
popup_menu = { opacity = false; }
};

# Прозрачность i3status и dmenu.
opacity-rule = [
\"70:class_g = 'i3bar' && !focused\",
\"80:class_g = 'dmenu' && !focused\"
];" > /mnt/home/"$username"/.config/picom.conf
#
#Создание xresources.
echo -e "\033[31mСоздание xresources.\033[32m"
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
!Укажите шаблон для масштабируемых шрифтов.
xterm*faceName: Noto Sans Mono
!
!Размер шрифтов.
xterm*faceSize: '"$font"'
!
!Указывает цвет фона.
xterm*background: #2b0f2b
!Определяет цвет, который будет использоваться для переднего плана.
xterm*foreground: #2bf92b
!
!Указывает, должна ли отображаться полоса прокрутки.
xterm*scrollBar: true
!
!Определяет ширину полосы прокрутки.
xterm*scrollbar.width: '"$(($font/2))"'
!
!Указывает, должно ли нажатие клавиши автоматически перемещать полосу прокрутки в нижнюю часть области прокрутки.
xterm*scrollKey: true
!
!Указывает, должна ли полоса прокрутки отображаться справа.
xterm*rightScrollBar: true
!
!Размер курсора.
Xcursor.size: '"$(($font*3))"'
Xcursor.theme: Adwaita
!
!
!Настройка внешнего вида xscreensaver.
!
!Указывает шрифт.
xscreensaver-auth.?.Dialog.headingFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.Dialog.bodyFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.Dialog.labelFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.Dialog.unameFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.Dialog.buttonFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.Dialog.dateFont: Noto Sans Mono '"$font"'
xscreensaver-auth.?.passwd.passwdFont: Noto Sans Mono '"$font"'
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
echo -e "\033[31mСоздание конфига i3.\033[32m"
mkdir -p /mnt/home/"$username"/.config/i3
echo '########### Основные настройки ###########
#
# Назначаем клавишу MOD, Mod4 - это клавиша WIN.
set $mod Mod4
#
# Закрыть окно в фокусе.
bindsym $mod+Shift+q kill
# Средняя кнопка мыши над заголовком закрывает окно.
bindsym --release button2 kill
#
# Изменить фокус на другое окно (semicolon - это клавиша ;:жЖ).
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right
# Альтернативные настройки смены фокуса на другое окно.
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
#
# Переместить окно.
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right
# Альтернативные настройки перемешения окна.
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
# Боковые кнопки мыши перемещают окно.
bindsym button9 move left
bindsym button8 move right
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
# Делаем окно плавающим.
bindsym $mod+Shift+space floating toggle
# Правая кнопка мыши делает окно плавающим.
bindsym button3 floating toggle
bindsym $mod+button3 floating toggle
#
# Изменить фокус между мозаичными / плавающими окнами.
bindsym $mod+space focus mode_toggle
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
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m "Вы действительно хотите выйти из i3? Это завершит вашу сессию X." -B "Да, выйти из i3" "i3-msg exit""
#
# Войти в режим изменения размеров окон.
bindsym $mod+r mode "resize"
# Изменить размер окна (можно использовать мышь).
mode "resize" {
#
        # Настройки смены размеров окон.
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt
        #
        # Альтернативные настройки смены размеров окон (мне показались более удобными).
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        #
        # Выйти из режима изменения размеров окон.
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}
#
# Некоторые видеодрайверы X11 обеспечивают поддержку только Xinerama вместо RandR.
# В такой ситуации нужно сказать i3, чтобы он явно использовал подчиненный Xinerama API.
force_xinerama yes
#
########### Внешний вид ###########
#
# Шрифт для заголовков окон. Также будет использоваться ibar, если не выбран другой шрифт.
font pango:Snowstorm Kraft '"$(($font*2))"'
#
# Просветы между окнами.
gaps inner '"$font"'
#
# Толщина границы окна.
default_border normal '"$(($font/3))"'
#
# Толщина границы плавающего окна.
default_floating_border normal '"$(($font/3))"'
#
# Устанавливаем цвет рамки активного окна #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.focused #2b2bf9 #2b2bf9 #2bf92b #2b2bf9 #2b2bf9
#
# Устанавливаем цвет рамки неактивного окна #Граница #ФонТекста #Текст #Индикатор #ДочерняяГраница.
client.unfocused #2b2b0f #2b2b0f #b2b2b2 #2b2b0f #2b2b0f
#
# Печатать все заголовки окон жирным, красным шрифтом.
# for_window [all] title_format "<span foreground="#d64c2f"><b>Заголовок | %title</b></span>"
#
# Включить значки окон для всех окон с дополнительным горизонтальным отступом.
for_window [all] title_window_icon padding '"$(($font/3))"'px
#
# Внешний вид XTerm
# Включить плавающий режим для всех окон XTerm.
for_window [class="XTerm"] floating enable
# Сделать границу в 0 пикселей для всех окон XTerm.
for_window [class="XTerm"] border normal 0
# Липкие плавающие окна, окно XTerm прилипло к стеклу.
for_window [class="XTerm"] sticky enable
# Задаем размеры окна XTerm.
for_window [class="XTerm"] resize set '"$xterm"'
#
########### Автозапуск программ ###########
#
# Запуск геолокации (--no-startup-id убирает курсор загрузки).
exec --no-startup-id /usr/lib/geoclue-2.0/demos/agent
#
# Автозапуск volctl.
exec --no-startup-id volctl
#
# Автозапуск flameshot.
exec --no-startup-id flameshot
#
# Автозапуск copyq.
exec --no-startup-id copyq
#
# Автозапуск obs.
exec --no-startup-id obs
#
# Автозапуск tint2.
exec --no-startup-id tint2
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
# Приветствие в течении 10 сек.
exec --no-startup-id notify-send -t 10000 "✊Доброго времени суток✊"
#
# Автозапуск xscreensaver.
exec --no-startup-id xscreensaver --no-splash
#
# Автозапуск dolphin.
exec --no-startup-id dolphin --daemon
#
# Автозапуск steam, через gamemod "exec --no-startup-id gamemoderun steam -silent %U".
exec --no-startup-id steam -silent %U
#
# Автозапуск telegram.
exec --no-startup-id telegram-desktop -startintray -- %u
#
# Автозапуск variety.
exec --no-startup-id variety
#
# Автоматическая разблокировка KWallet.
exec --no-startup-id /usr/lib/pam_kwallet_init
#
########### Горячие клавиши запуска программ ###########
#
# Используйте mod+enter, чтобы запустить терминал ("i3-sensible-terminal" можно заменить "xterm", "terminator" или любым другим на выбор).
bindsym $mod+Return exec xterm
#
# Запуск dmenu (программа запуска) с параметрами шрифта, приглашения, цвета фона.
bindsym $mod+d exec --no-startup-id dmenu_run -fn "Snowstorm Kraft-'"$(($font*3))"'" -p "Поиск программы:" -nb "#2b2b2b" -sf "#2b2bf9" -nf "#2bf92b" -sb "#f92b2b"
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
        font pango:Noto Sans Mono '"$(($font/2+$font))"'
        #
        # Назначить цвета.
        colors {
            # Цвет фона i3status.
            background #2b2b2b
            #
            # Цвет текста в i3status.
            statusline #b2b2b2
            #
            # Цвет разделителя в i3status.
            separator #f92b2b
            }
         # Сделайте снимок экрана, щелкнув правой кнопкой мыши на панели (--no-startup-id убирает курсор загрузки).
         bindsym --release button3 exec --no-startup-id import ~/latest-screenshot.png
}' > /mnt/home/"$username"/.config/i3/config
#
#Создание конфига i3status.
echo -e "\033[31mСоздание конфига i3status.\033[32m"
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
    format_up = "🖧: %ip " #Формат вывода.
    format_down = "" } #При неактивном процессе блок будет отсутствовать.
wireless _first_ { #Индикатор WI-FI.
    format_up = "📶%quality | %frequency | %essid: %ip " #Формат вывода.
    format_down = "" } #При неактивном процессе блок будет отсутствовать.
battery all { #Индикатор батареи
    format = "%status %percentage" #Формат вывода.
    last_full_capacity = true #Процент заряда.
    format_down = "" #При неактивном процессе блок будет отсутствовать.
    status_chr = "🔌" #Подзарядка.
    status_bat = "🔋" #Режим работы от батареи.
    path = "/sys/class/power_supply/BAT%d/uevent" #Путь данных.
    low_threshold = 10 } #Нижний порог заряда.
memory { #Индикатор ram
    format = "RAM: %used /%total" #Формат вывода.
    threshold_degraded = 10% #Желтый порог.
    threshold_critical = 5% #Красный порог.
    format_degraded = "RAM: %used /%total" } #Формат вывода желтого/красного порога.
cpu_usage { #Использование ЦП.
    format = "CPU: %usage" } #Формат вывода.
cpu_temperature 0 { #Температура ЦП.
    format = "Θ°CPU: %degrees°C" #Формат вывода.
    max_threshold = "70" #Красный порог.
    format_above_threshold = "Θ CPU: %degrees°C" #Формат вывода красного порога.
    path = "/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input" } #Путь данных.path: /sys/devices/platform/coretemp.0/temp1_input
tztime 1 { #Вывод даты и времени.
    format = "📆 %a %d-%m-%Y(%W)" } #Формат вывода.
tztime 2 { #Вывод даты и времени.
    format = "⌛ %H:%M:%S %Z" } #Формат вывода.
tztime 0 { #Вывод разделителя.
    format = "|" } #Формат вывода.' > /mnt/home/"$username"/.i3status.conf
#
#Создание конфига redshift.
echo -e "\033[31mСоздание конфига redshift.\033[32m"
echo '[redshift]
allowed=true
system=false
users=' >> /mnt/etc/geoclue/geoclue.conf
#
#Отключение запроса пароля.
echo -e "\033[31mОтключение запроса пароля.\033[32m"
echo 'polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});' > /mnt/etc/polkit-1/rules.d/49-nopasswd_global.rules
#
#Создание директории и конфига qt5ct.
echo -e "\033[31mСоздание конфига qt5ct.\033[32m"
if [ "$font" = "6" ]; then fontqt="(\0\0\0@\0\0\0\x1c\0N\0o\0t\0o\0 \0S\0\x61\0n\0s\0 \0M\0o\0n\0o@\x18\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)"
elif [ "$font" = "8" ]; then fontqt="(\0\0\0@\0\0\0\x1c\0N\0o\0t\0o\0 \0S\0\x61\0n\0s\0 \0M\0o\0n\0o@ \0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)"
elif [ "$font" = "10" ]; then fontqt="(\0\0\0@\0\0\0\x1c\0N\0o\0t\0o\0 \0S\0\x61\0n\0s\0 \0M\0o\0n\0o@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)"
fi
mkdir -p /mnt/home/"$username"/.config/qt5ct
echo '[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/airy.conf
custom_palette=false
icon_theme=ePapirus-Dark
standard_dialogs=default
style=Adwaita-Dark
[Fonts]
fixed=@Variant'"$fontqt"'
general=@Variant'"$fontqt"'
[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines='"$(($font/2))"'
[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\"\0\0\0\x88\0\0\xe\xdd\0\0\b\x1e\0\0\0+\0\0\0\x88\0\0\xe\xd4\0\0\b\x15\0\0\0\0\0\0\0\0\xf\0\0\0\0+\0\0\0\x88\0\0\xe\xd4\0\0\b\x15)
[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()' > /mnt/home/$username/.config/qt5ct/qt5ct.conf
#
#Создание директории и конфига gtk.
echo -e "\033[31mСоздание конфига gtk.\033[32m"
mkdir -p /mnt/home/$username/.config/gtk-3.0/
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-button-images=1
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size='"$(($font*3))"'
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=false
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-font-name=Noto Sans Mono '"$font"'
gtk-icon-theme-name=Papirus-Dark
gtk-menu-images=1
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=false
gtk-theme-name=Adwaita-dark
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
gtk-xft-rgba=rgb' > /mnt/home/"$username"/.config/gtk-3.0/settings.ini
#
#Создание директории и конфига tint2.
echo -e "\033[31mСоздание конфига tint2.\033[32m"
mkdir -p /mnt/home/"$username"/.config/tint2
echo '#---- Generated by tint2conf df32 ----
# See https://gitlab.com/o9000/tint2/wikis/Configure for
# full documentation of the configuration options.
#-------------------------------------
# Gradients
#-------------------------------------
# Backgrounds
# Background 1: Панель
rounded = 0
border_width = 0
border_sides = TBLR
border_content_tint_weight = 0
background_content_tint_weight = 0
background_color = #2b2b2b 80
border_color = #000000 30
background_color_hover = #000000 60
border_color_hover = #000000 30
background_color_pressed = #000000 60
border_color_pressed = #000000 30
# Background 2: Задача по умолчанию, Свернутая задача
rounded = 4
border_width = 1
border_sides = TBLR
border_content_tint_weight = 0
background_content_tint_weight = 0
background_color = #777777 20
border_color = #777777 30
background_color_hover = #aaaaaa 22
border_color_hover = #eaeaea 44
background_color_pressed = #555555 4
border_color_pressed = #eaeaea 44
# Background 3: Активная задача
rounded = 4
border_width = 1
border_sides = TBLR
border_content_tint_weight = 0
background_content_tint_weight = 0
background_color = #777777 20
border_color = #ffffff 40
background_color_hover = #aaaaaa 22
border_color_hover = #eaeaea 44
background_color_pressed = #555555 4
border_color_pressed = #eaeaea 44
# Background 4: Неотложная задача
rounded = 4
border_width = 1
border_sides = TBLR
border_content_tint_weight = 0
background_content_tint_weight = 0
background_color = #aa4400 100
border_color = #aa7733 100
background_color_hover = #cc7700 100
border_color_hover = #aa7733 100
background_color_pressed = #555555 4
border_color_pressed = #aa7733 100
# Background 5: Всплывающий текст
rounded = 1
border_width = 1
border_sides = TBLR
border_content_tint_weight = 0
background_content_tint_weight = 0
background_color = #222222 100
border_color = #333333 100
background_color_hover = #ffffaa 100
border_color_hover = #000000 100
background_color_pressed = #ffffaa 100
border_color_pressed = #000000 100
#-------------------------------------
# Panel
panel_items = L
panel_size = 100% '"$gap"'
panel_margin = 0 0
panel_padding = 2 0 2
panel_background_id = 1
wm_menu = 1
panel_dock = 0
panel_pivot_struts = 0
panel_position = top center horizontal
panel_layer = top
panel_monitor = all
panel_shrink = 0
autohide = 0
autohide_show_timeout = 0
autohide_hide_timeout = 0.5
autohide_height = 2
strut_policy = follow_size
panel_window_name = tint2
disable_transparency = 1
mouse_effects = 1
font_shadow = 0
mouse_hover_icon_asb = 100 0 10
mouse_pressed_icon_asb = 100 0 0
scale_relative_to_dpi = 0
scale_relative_to_screen_height = 0
#-------------------------------------
# Taskbar
taskbar_mode = single_desktop
taskbar_hide_if_empty = 0
taskbar_padding = 0 0 2
taskbar_background_id = 0
taskbar_active_background_id = 0
taskbar_name = 1
taskbar_hide_inactive_tasks = 0
taskbar_hide_different_monitor = 0
taskbar_hide_different_desktop = 0
taskbar_always_show_all_desktop_tasks = 0
taskbar_name_padding = 4 2
taskbar_name_background_id = 0
taskbar_name_active_background_id = 0
taskbar_name_font_color = #e3e3e3 100
taskbar_name_active_font_color = #ffffff 100
taskbar_distribute_size = 0
taskbar_sort_order = none
task_align = left
#-------------------------------------
# Task
task_text = 1
task_icon = 1
task_centered = 1
urgent_nb_of_blink = 100000
task_maximum_size = 150 35
task_padding = 2 2 4
task_tooltip = 1
task_thumbnail = 0
task_thumbnail_size = 210
task_font_color = #ffffff 100
task_background_id = 2
task_active_background_id = 3
task_urgent_background_id = 4
task_iconified_background_id = 2
mouse_left = toggle_iconify
mouse_middle = none
mouse_right = close
mouse_scroll_up = toggle
mouse_scroll_down = iconify
#-------------------------------------
# System tray (notification area)
systray_padding = 0 4 2
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 24
systray_icon_asb = 100 0 0
systray_monitor = 1
systray_name_filter =
#-------------------------------------
# Launcher
launcher_padding = 2 4 2
launcher_background_id = 0
launcher_icon_background_id = 0
launcher_icon_size = '"$gap"'
launcher_icon_asb = 100 0 0
launcher_icon_theme = Papirus-Dark
launcher_icon_theme_override = 0
startup_notifications = 1
launcher_tooltip = 1
launcher_item_app = tint2conf.desktop
launcher_item_app = firefox.desktop
launcher_item_app = /usr/share/applications/org.kde.dolphin.desktop
launcher_item_app = /usr/share/applications/org.gnome.Cheese.desktop
launcher_item_app = /usr/share/applications/org.kde.kate.desktop
launcher_item_app = /usr/share/applications/com.obsproject.Studio.desktop
launcher_item_app = /usr/share/applications/vlc.desktop
launcher_item_app = /usr/share/applications/org.kde.step.desktop
launcher_item_app = /usr/share/applications/hardinfo.desktop
launcher_item_app = /usr/share/applications/audacity.desktop
launcher_item_app = /usr/share/applications/org.kde.skanlite.desktop
#-------------------------------------
# Clock
time1_format = %H:%M
time2_format = %A %d %B
time1_timezone =
time2_timezone =
clock_font_color = #ffffff 100
clock_padding = 2 0
clock_background_id = 0
clock_tooltip =
clock_tooltip_timezone =
clock_lclick_command =
clock_rclick_command = orage
clock_mclick_command =
clock_uwheel_command =
clock_dwheel_command =
#-------------------------------------
# Battery
battery_tooltip = 1
battery_low_status = 10
battery_low_cmd = xmessage \047tint2: Battery low!\047
battery_full_cmd =
battery_font_color = #ffffff 100
bat1_format =
bat2_format =
battery_padding = 1 0
battery_background_id = 0
battery_hide = 101
battery_lclick_command =
battery_rclick_command =
battery_mclick_command =
battery_uwheel_command =
battery_dwheel_command =
ac_connected_cmd =
ac_disconnected_cmd =
#-------------------------------------
# Tooltip
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.1
tooltip_padding = 4 4
tooltip_background_id = 5
tooltip_font_color = #dddddd 100' > /mnt/home/"$username"/.config/tint2/tint2rc
#
#Создание конфига kdeglobals.
echo -e "\033[31mСоздание конфига kdeglobals.\033[32m"
echo '[$Version]
update_info=filepicker.upd:filepicker-remove-old-previews-entry,fonts_global.upd:Fonts_Global,fonts_global_toolbar.upd:Fonts_Global_Toolbar,icons_remove_effects.upd:IconsRemoveEffects,kwin.upd:animation-speed,style_widgetstyle_default_breeze.upd:StyleWidgetStyleDefaultBreeze
[ColorEffects:Disabled]
ChangeSelectionColor=
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
Enable=
IntensityAmount=0.1
IntensityEffect=2
[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0
[Colors:Button]
BackgroundAlternate=30,87,116
BackgroundNormal=49,54,59
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:Complementary]
BackgroundAlternate=30,87,116
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:Header]
BackgroundAlternate=42,46,50
BackgroundNormal=49,54,59
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:Header][Inactive]
BackgroundAlternate=49,54,59
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:Selection]
BackgroundAlternate=30,87,116
BackgroundNormal=61,174,233
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=252,252,252
ForegroundInactive=161,169,177
ForegroundLink=253,188,75
ForegroundNegative=176,55,69
ForegroundNeutral=198,92,0
ForegroundNormal=252,252,252
ForegroundPositive=23,104,57
ForegroundVisited=155,89,182
[Colors:Tooltip]
BackgroundAlternate=42,46,50
BackgroundNormal=49,54,59
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:View]
BackgroundAlternate=35,38,41
BackgroundNormal=43,43,43
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[Colors:Window]
BackgroundAlternate=49,54,59
BackgroundNormal=42,46,50
DecorationFocus=61,174,233
DecorationHover=61,174,233
ForegroundActive=61,174,233
ForegroundInactive=161,169,177
ForegroundLink=29,153,243
ForegroundNegative=218,68,83
ForegroundNeutral=246,116,0
ForegroundNormal=252,252,252
ForegroundPositive=39,174,96
ForegroundVisited=155,89,182
[DirSelect Dialog]
DirSelectDialog Size=920,588
History Items[$e]=file:///data/torrent,file:///data,file:$HOME/Загрузки
[General]
BrowserApplication=firefox.desktop
ColorSchemeHash=bcce7c1c6181c5e14e633cd8301e7a9036b67ac6
TerminalApplication=xterm
TerminalService=xterm.desktop
XftHintStyle=hintslight
XftSubPixel=rgb
fixed=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
font=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
menuFont=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
smallestReadableFont=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
toolBarFont=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
[Icons]
Theme=Papirus-Dark
[KDE]
AnimationDurationFactor=0
LookAndFeelPackage=org.kde.breezedark.desktop
ShowDeleteCommand=false
widgetStyle=Windows
[KFileDialog Settings]
Allow Expansion=false
Automatically select filename extension=true
Breadcrumb Navigation=true
Decoration position=2
LocationCombo Completionmode=5
PathCombo Completionmode=5
Show Bookmarks=false
Show Full Path=false
Show Inline Previews=true
Show Preview=false
Show Speedbar=true
Show hidden files=false
Sort by=Name
Sort directories first=true
Sort hidden files last=false
Sort reversed=false
Speedbar Width=193
View Style=DetailTree
[KScreen]
ScaleFactor=1.25
ScreenScaleFactors=DP-0=1.25;DP-1=1.25;HDMI-0=1.25;DP-2=1.25;DP-3=1.25;DP-4=1.25;DP-5=1.25;USB-C-0=1.25;
[PreviewSettings]
MaximumRemoteSize=5242880
[WM]
activeBackground=49,54,59
activeBlend=252,252,252
activeFont=Noto Sans Mono,'"$font"',-1,5,50,0,0,0,0,0
activeForeground=252,252,252
inactiveBackground=42,46,50
inactiveBlend=161,169,177
inactiveForeground=161,169,177' > /mnt/home/"$username"/.config/kdeglobals
#
#Установка атмосферных шрифтов.
echo -e "\033[31mУстановка атмосферных шрифтов.\033[32m"
arch-chroot /mnt  sh -c "cd /usr/share/fonts/
curl -L https://github.com/stardestart/arch/raw/main/font/Snowstorm.zip > Snowstorm.zip
curl -L https://github.com/stardestart/arch/raw/main/font/30144_PostIndex.ttf > 30144_PostIndex.ttf
unzip -o *.zip
rm *.zip *.txt"
#
#Передача интернет настроек в установленную систему.
echo -e "\033[31mПередача интернет настроек в установленную систему.\033[32m"
if [ -z "$namewifi" ]; then arch-chroot /mnt ip link set "$netdev" up
    else
        arch-chroot /mnt pacman -Sy iwd  --noconfirm
        arch-chroot /mnt systemctl enable iwd
        arch-chroot /mnt ip link set "$netdev" up
        mkdir -p /mnt/var/lib/iwd
        cp /var/lib/iwd/"$namewifi".psk /mnt/var/lib/iwd/"$namewifi".psk
fi
#
#Автозапуск служб.
echo -e "\033[31mАвтозапуск служб.\033[32m"
arch-chroot /mnt systemctl enable reflector.timer xdm-archlinux dhcpcd avahi-daemon
arch-chroot /mnt systemctl --user --global enable redshift-gtk
#
#Передача прав созданному пользователю.
echo -e "\033[31mПередача прав созданному пользователю.\033[32m"
arch-chroot /mnt chown -R "$username":users /home/"$username"/
#
#Установка помощника yay для работы с AUR.
echo -e "\033[31mУстановка помощника yay для работы с AUR.\033[32m"
arch-chroot /mnt/ sudo -u "$username" sh -c 'cd /home/'"$username"'/
git clone https://aur.archlinux.org/yay.git
cd /home/'"$username"'/yay
BUILDDIR=/tmp/makepkg makepkg -i --noconfirm'
rm -Rf /mnt/home/"$username"/yay
#
#Установка программ из AUR.
echo -e "\033[31mУстановка программ из AUR.\033[32m"
arch-chroot /mnt/ sudo -u "$username" yay -S transset-df volctl --noconfirm
#
#Установка завершена, после перезагрузки вас встретит настроенная и готовая к работе ОС.
echo -e "\033[31mУстановка завершена, после перезагрузки вас встретит настроенная и готовая к работе ОС.\033[32m"
#fdisk -l
lsblk -l
