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
pacman -Scc --noconfirm
gpg-connect-agent reloadagent /bye
rm /var/lib/pacman/db.lck
rm -R /root/.gnupg/
rm -R /etc/pacman.d/gnupg/
#Переменная назначит образ микрокода ЦП для UEFI загрузчика.
microcode=""
#Переменная сохранит имя сетевого устройства для дальнейшей установки/настройки/расчета.
netdev="$(ip -br link show | grep -vEi "unknown|down" | awk '{print $1}' | xargs)"
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
p5=""
p6=""
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
#Переменная сохранит размер шрифта firefox.
fox=""
#Переменная сохранит шифр авторизации grub.
grubsha=""
#Переменная сохранит размер root-раздела.
rootsize=""
#Переменная сохранит размер var-раздела.
varsize=""
#Переменная сохранит кулеры.
fanconky=""
#
#Определяем процессор.
echo -e "\033[36mОпределяем процессор.\033[0m"
if [ -n "$(lscpu | grep -i amd)" ]; then microcode="\ninitrd /amd-ucode.img"
elif [ -n "$(lscpu | grep -i intel)" ]; then microcode="\ninitrd /intel-ucode.img"
fi
echo -e "\033[36mПроцессор:"$(lscpu | grep -i "model name")"\033[0m"
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
        PS3="$(echo -e "\033[47m\033[30mПункт №:\033[0m\n\033[32m>")"
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
        p5="5"
        p6="6"
    else
        p1="p1"
        p2="p2"
        p3="p3"
        p4="p4"
        p5="p5"
        p6="p6"
fi
#
#Создание пользователя.
echo -e "\033[36mСоздание пользователя.\033[0m"
echo -e "\033[47m\033[30mВведите имя компьютера:\033[0m\033[32m";read -p ">" hostname
echo -e "\033[47m\033[30mВведите имя пользователя:\033[0m\033[32m";read -p ">" username
echo -e "\033[47m\033[30mВведите пароль для "$username":\033[0m\033[32m";read -p ">" passuser
echo -e "\033[47m\033[30mВведите пароль для root:\033[0m\033[32m";read -p ">" passroot
echo -e "\033[36mВыберите разрешение монитора:\033[32m"
PS3="$(echo -e "\033[47m\033[30mПункт №:\033[0m\n\033[32m>")"
select menuscreen in "~480p." "~720p-1080p." "~4K."
do
    case "$menuscreen" in
        "~480p.")
            font=10
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
if [ "$ram" -ge 120 ]; then swap="11G"
elif [ "$ram" -ge 60 ]; then swap="8G"
elif [ "$ram" -ge 30 ]; then swap="6G"
elif [ "$ram" -ge 20 ]; then swap="5G"
elif [ "$ram" -ge 10 ]; then swap="4G"
elif [ "$ram" -ge 8 ]; then swap="3G"
elif [ "$ram" -ge 4 ]; then swap="2G"
elif [ "$ram" -lt 4 ]; then swap="1G"
fi
echo -e "\033[36mРазмер SWAP раздела: $swap\033[0m"
#
#Вычисление var и root разделов.
echo -e "\033[36mВычисление var и root разделов.\033[0m"
rootsize="$(fdisk -l /dev/"$sysdisk" | head -n1 | awk '{print $3}')"
rootsize=$(bc << EOF
$rootsize/5*2
EOF
)
varsize=$(bc << EOF
$rootsize/2
EOF
)
if [ $rootsize -lt 20 ]; then rootsize=20; fi
varsize="$varsize"G
echo -e "\033[36mРазмер var-раздела: $varsize\033[0m"
rootsize="$rootsize"G
echo -e "\033[36mРазмер root-раздела: $rootsize\033[0m"
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

+$rootsize
n
5

+$varsize
n
6


w
EOF
mkfs.ext2 /dev/"$sysdisk""$p1" -L boot<<EOF
y
EOF
mkswap /dev/"$sysdisk""$p3" -L swap
mkfs.ext4 /dev/"$sysdisk""$p4" -L root<<EOF
y
EOF
mkfs.ext4 /dev/"$sysdisk""$p5" -L var<<EOF
y
EOF
mkfs.ext4 /dev/"$sysdisk""$p6" -L home<<EOF
y
EOF
mount /dev/"$sysdisk""$p4" /mnt
mount -o nodev,noexec,nosuid --mkdir /dev/"$sysdisk""$p1" /mnt/boot
mount -o nodev,nosuid --mkdir /dev/"$sysdisk""$p5" /mnt/var
mount -o nodev,nosuid --mkdir /dev/"$sysdisk""$p6" /mnt/home
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

+$rootsize
n
4

+$varsize
n
5


w
EOF
mkfs.fat -F32 /dev/"$sysdisk""$p1" -n boot<<EOF
y
EOF
mkswap /dev/"$sysdisk""$p2" -L swap
mkfs.ext4 /dev/"$sysdisk""$p3" -L root<<EOF
y
EOF
mkfs.ext4 /dev/"$sysdisk""$p4" -L var<<EOF
y
EOF
mkfs.ext4 /dev/"$sysdisk""$p5" -L home<<EOF
y
EOF
mount /dev/"$sysdisk""$p3" /mnt
mount -o nodev,noexec,nosuid --mkdir /dev/"$sysdisk""$p1" /mnt/boot
mount -o nodev,nosuid --mkdir /dev/"$sysdisk""$p4" /mnt/var
mount -o nodev,nosuid --mkdir /dev/"$sysdisk""$p5" /mnt/home
swapon /dev/"$sysdisk""$p2"
fi
#
#Установка и настройка программы для фильтрования зеркал и обновление ключей.
echo -e "\033[36mУстановка и настройка программы для фильтрования зеркал и обновление ключей.\033[0m"
sed -i '/= Required DatabaseOptional/c\SigLevel = Required DatabaseOptional TrustAll' /etc/pacman.conf
sed -i "s/#Color/Color/" /etc/pacman.conf
pacman-key --init
pacman-key --populate archlinux
pacman -Sy reflector --noconfirm
pacman -Sy glibc --noconfirm
pacman -Sy lib32-glibc --noconfirm
pacman -Sy sad --noconfirm
pacman -Sy coreutils --noconfirm
echo -e "Старый список зеркал."
cat /etc/pacman.d/mirrorlist
reflector --latest 20 --protocol https --sort rate --download-timeout 2 --save /etc/pacman.d/mirrorlist
echo -e "Новый список зеркал."
cat /etc/pacman.d/mirrorlist
#
#Установка ОС.
echo -e "\033[36mУстановка ОС.\033[0m"
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware
#
#Добавление модулей.
echo -e "\033[36mДобавление модулей.\033[0m"
sed -i 's/HOOKS=(base udev/HOOKS=(base udev resume/' /mnt/etc/mkinitcpio.conf
echo 'btusb' > /mnt/etc/modules-load.d/modules.conf
#
#Установка часового пояса.
echo -e "\033[36mУстановка часового пояса.\033[0m"
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$(curl https://ipapi.co/timezone)" /etc/localtime
arch-chroot /mnt hwclock --systohc
#
#Настройка локали.
echo -e "\033[36mНастройка локали.\033[0m"
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen
sed -i 's/#ru_RU.UTF-8/ru_RU.UTF-8/' /mnt/etc/locale.gen
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
#Установим дополнительное количество итераций для хеширование паролей.
sed -i 's/nullok/nullok rounds=500000/' /mnt/etc/pam.d/passwd
echo "SHA_CRYPT_MIN_ROUNDS 500000" >> /mnt/etc/login.defs
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
#Установка загрузчика.
echo -e "\033[36mУстановка загрузчика.\033[0m"
if [ -z "$(efibootmgr | grep Boot)" ];
    then
        arch-chroot /mnt pacman -Sy grub --noconfirm
        arch-chroot /mnt grub-install /dev/"$sysdisk"
        sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=2/' /mnt/etc/default/grub
        sed -i 's/#GRUB_DISABLE_RECOVERY=true/GRUB_DISABLE_RECOVERY=true/' /mnt/etc/default/grub
        sed -i 's/GRUB_DISABLE_LINUX_UUID=true/#GRUB_DISABLE_LINUX_UUID=true/' /mnt/etc/default/grub
        sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="resume=\/dev\/'"$sysdisk"''"$p3"' /' /mnt/etc/default/grub
        grubsha=$(grub-mkpasswd-pbkdf2 << EOF
$passuser
$passuser
EOF
)
        grubsha="$(echo $grubsha | awk '{print $NF}')"
        sed -i 's/CLASS="--class gnu-linux --class gnu --class os"/CLASS="--class gnu-linux --class gnu --class os --unrestricted"/' /mnt/etc/grub.d/10_linux
        echo 'cat << EOF
set superusers='"$username"'
password_pbkdf2 '"$username"' '"$grubsha"'
EOF' >> /mnt/etc/grub.d/00_header
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    else
        arch-chroot /mnt pacman -Sy efibootmgr --noconfirm
        arch-chroot /mnt bootctl install
        echo -e "default arch\ntimeout 2\neditor yes\nconsole-mode max" > /mnt/boot/loader/loader.conf
        echo -e "title Arch Linux\nlinux /vmlinuz-linux-zen"$microcode"\ninitrd /initramfs-linux-zen.img\noptions root=/dev/"$sysdisk""$p3" rw\noptions resume=/dev/"$sysdisk""$p2"" > /mnt/boot/loader/entries/arch.conf
fi
#
#Установка микроинструкции для процессора.
echo -e "\033[36mУстановка микроинструкций для процессора.\033[0m"
if [ "$microcode" = "\ninitrd /amd-ucode.img" ]; then arch-chroot /mnt pacman -Sy amd-ucode --noconfirm
elif [ "$microcode" = "\ninitrd /intel-ucode.img" ]; then arch-chroot /mnt pacman -Sy intel-ucode iucode-tool --noconfirm
fi
#
#Настройка установщика pacman.
echo -e "\033[36mНастройка установщика pacman.\033[0m"
sed -i "s/#Color/Color/" /mnt/etc/pacman.conf
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n[kde-unstable]\nInclude = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
#
#Настройка sysctl (Параметры ядра).
echo -e "\033[36mНастройка sysctl (Параметры ядра).\033[0m"
echo "kernel.sysrq=1
dev.tty.ldisc_autoload=0
fs.protected_fifos=2
fs.protected_hardlinks=1
fs.protected_regular=2
fs.protected_symlinks=1
fs.suid_dumpable=0
kernel.core_uses_pid=1
kernel.ctrl-alt-del=0
kernel.dmesg_restrict=1
kernel.kexec_load_disabled=1
kernel.kptr_restrict=2
kernel.perf_event_paranoid=3
kernel.randomize_va_space=2
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.secure_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_source_route=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.bootp_relay=0
net.ipv4.conf.all.mc_forwarding=0
net.ipv4.conf.all.proxy_arp=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_all=1
net.ipv6.icmp.echo_ignore_all=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_time=60
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_keepalive_probes=6
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_tw_reuse=1
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50" > /mnt/etc/sysctl.d/99-sysctl.conf
#
#Установка видеодрайвера.
echo -e "\033[36mУстановка видеодрайвера.\033[0m"
if [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then
    if [ -n "$(lspci | grep -i vga | grep -i nvidia | grep -E 'TU1|GA1|GV1|GP10|GM20|GM10')" ]; then
        arch-chroot /mnt pacman -Sy nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia opencv-cuda nvtop cuda --noconfirm
        sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf
    else
        arch-chroot /mnt pacman -Sy xf86-video-nouveau --noconfirm
        sed -i 's/MODULES=()/MODULES=(nouveau)/' /mnt/etc/mkinitcpio.conf
    fi
elif [ -n "$(lspci | grep -i vga | grep -iE 'vmware svga|virtualbox')" ]; then
    arch-chroot /mnt pacman -Sy virtualbox-guest-utils --noconfirm
    sed -i 's/MODULES=()/MODULES=(vmwgfx vboxvideo vboxguest)/' /mnt/etc/mkinitcpio.conf
elif [ -n "$(lspci | grep -i vga | grep AMD)" ]; then
    arch-chroot /mnt pacman -Sy xf86-video-ati xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon --noconfirm
    sed -i 's/MODULES=()/MODULES=(amdgpu radeon)/' /mnt/etc/mkinitcpio.conf
elif [ -n "$(lspci | grep -i vga | grep -i intel)" ]; then
    arch-chroot /mnt pacman -Sy vulkan-intel intel-media-driver libva-intel-driver --noconfirm
    sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
fi
#Установка компонентов и программ ОС.
echo -e "\033[36mУстановка компонентов и программ ОС.\033[0m"
arch-chroot /mnt pacman -Sy xorg-server xorg-xinit xterm i3-gaps i3status perl-anyevent-i3 perl-json-xs dmenu xdm-archlinux firefox firefox-i18n-ru firefox-spell-ru firefox-ublock-origin firefox-dark-reader firefox-adblock-plus flatpak xdg-desktop-portal-gtk network-manager-applet networkmanager-strongswan wireless_tools krdc blueman bluez bluez-utils bluez-qt git mc htop nano dhcpcd imagemagick acpid clinfo avahi reflector go libnotify autocutsel openssh haveged dbus-broker x11vnc polkit kwalletmanager kwallet-pam xlockmore xautolock gparted archlinux-xdg-menu ark ntfs-3g dosfstools unzip smartmontools dolphin kdf filelight ifuse usbmuxd libplist libimobiledevice curlftpfs samba kimageformats ffmpegthumbnailer kdegraphics-thumbnailers qt5-imageformats kdesdk-thumbnailers ffmpegthumbs kdenetwork-filesharing smb4k papirus-icon-theme picom redshift lxqt-panel grc flameshot dunst gnome-themes-extra archlinux-wallpaper feh conky freetype2 ttf-fantasque-sans-mono neofetch alsa-utils alsa-plugins lib32-alsa-plugins alsa-firmware alsa-card-profiles pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol-qt aspell nuspell xed audacity cheese aspell-en aspell-ru ethtool pinta vlc libreoffice-still-ru hunspell hunspell-en_us hyphen hyphen-en libmythes mythes-en gimagereader-gtk tesseract-data-rus tesseract-data-eng kalgebra copyq kamera gwenview xreader gogglesmm sane skanlite nss-mdns cups-pk-helper cups cups-pdf system-config-printer steam wine winetricks wine-mono wine-gecko gamemode lib32-gamemode mpg123 lib32-mpg123 openal lib32-openal ocl-icd lib32-ocl-icd gstreamer lib32-gstreamer vkd3d lib32-vkd3d vulkan-icd-loader lib32-vulkan-icd-loader python-glfw lib32-vulkan-validation-layers vulkan-devel mesa lib32-mesa libva-mesa-driver mesa-vdpau ufw usbguard libpwquality kde-cli-tools ntp xdg-user-dirs geoclue rng-tools lib32-giflib gimp avidemux-qt kdenlive numlockx --noconfirm
#
#Поиск не смонтированных разделов, проверка наличия у них метки.
echo -e "\033[36mПоиск не смонтированных разделов, проверка наличия у них метки.\033[0m"
masslabel+='
#Блок "Диски и разделы".'
for (( j=0, i=1; i<="${#massparts[*]}"; i++, j++ ))
    do
        if [ -z "$(lsblk -no LABEL /dev/"${massparts[$j]}")" ];
            then
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then mount -o nodev,noexec,nosuid -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"${massparts[$j]}"
                    else mount -o nodev,noexec,nosuid --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"${massparts[$j]}"
                fi
masslabel+='
${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}~/Documents/Devices/'"${massparts[$j]}"'${hr 1}$color
(${fs_type /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'})${fs_bar '"$font"','"$(($font*6))"' /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} $alignr${color #f92b2b}${fs_used /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} / $color${fs_free /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} / ${color #b2b2b2}${fs_size /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'}'
            else
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then mount -o nodev,noexec,nosuid -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                    else mount -o nodev,noexec,nosuid --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                fi
masslabel+='
${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'${hr 1}$color
(${fs_type /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'})${fs_bar '"$font"','"$(($font*6))"' /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}$alignr${fs_used /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #f92b2b}${fs_free /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #b2b2b2}${fs_size /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}'
        fi
    done
#
#Копирование файла автоматического монтирования разделов.
echo -e "\033[36mКопирование файла автоматического монтирования разделов.\033[0m"
genfstab -U -p /mnt >> /mnt/etc/fstab
#
#Создание общего конфига загрузки оконного менеджера.
echo -e "\033[36mСоздание общего конфига загрузки оконного менеджера.\033[0m"
echo -e '#Указание на конфигурационные файлы.
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
xautolock -time 50 -locker "systemctl hibernate" -notify 1800 -notifier "xlock -mode matrix -delay 10000 -echokeys -echokey \047*\047" -detectsleep -noclose & #Автозапуск заставки.
exec i3 #Автозапуск i3.' | tee /mnt/home/"$username"/.xinitrc /mnt/root/.xinitrc
#
#Создание общего конфига клавиатуры.
echo -e "\033[36mСоздание общего конфига клавиатуры.\033[0m"
echo 'Section "InputClass"
Identifier "system-keyboard"
MatchIsKeyboard "on"
Option "XkbLayout" "us,ru"
Option "XkbOptions" "grp:alt_shift_toggle,terminate:ctrl_alt_bksp"
EndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
#
#Создание общего конфига сканера.
echo -e "\033[36mСоздание общего конфига сканера.\033[0m"
mkdir -p /mnt/etc/sane.d
echo -e "localhost\n192.168.0.0/24" >> /mnt/etc/sane.d/net.conf
#
#Формируется конфиг conky (Системный монитор).
#Температура ядер процессора.
echo -e "\033[36mФормируется конфиг conky (Системный монитор): Температура ядер процессора.\033[0m"
if [ -n "$(arch-chroot /mnt sensors | grep Core | awk '{print $1}' | xargs)" ]; then
coremass=($(arch-chroot /mnt sensors | grep Core | awk '{print $1}' | xargs))
coremassconf+='
#Температура ядер ЦП.'
for (( i=0, j=1; j<="${#coremass[*]}"; i++, j++ ))
    do
        coremassconf+='
${color #b2b2b2}${execi 10 sensors | grep "Core '$i':" | awk \047{print $1, $2}\047}$color$alignr${execi 10 sensors | grep "Core '$i':" | awk \047{print $3}\047}'
    done
fi
#
#Cкорость вращения кулеров
echo -e "\033[36mФормируется конфиг conky (Системный монитор): Cкорость вращения кулеров.\033[0m"
if [ -n "$(arch-chroot /mnt sensors | grep -i fan)" ]; then
fanconky='
#Блок "Cкорость вращения кулеров".
${color #f92b2b}FAN${hr 3}
$color${execi 10 sensors | grep -i fan}'
fi
#
#Параметры для видеокарт nvidia.
echo -e "\033[36mФормируется конфиг conky (Системный монитор): Параметры для видеокарт nvidia.\033[0m"
if [ -n "$(lspci | grep -i vga | grep -i nvidia)" ]; then
    nvidiac='
#Блок "Видеокарта Nvidia".
${color #f92b2b}GPU${hr 3}
${color #b2b2b2}Частота ГП:$color$alignr${nvidia gpufreq} Mhz
${color #b2b2b2}Видео ОЗУ:$color$alignr${nvidia mem} / ${nvidia memmax} MiB
${color #b2b2b2}Температура ГП:$color$alignr${nvidia temp} °C / ${nvidia fanspeed} RPM'
fi
#
#Создание конфига conky (Системный монитор).
echo -e "\033[36mСоздание конфига conky (Системный монитор).\033[0m"
mkdir -p /mnt/home/"$username"/.config/conky
echo -e 'conky.config = { --Внешний вид.
alignment = "top_right", --Располжение виджета.
border_inner_margin = '"$(($font/2))"', --Отступ от внутренних границ.
border_outer_margin = '"$(($font/2))"', --Отступ от края окна.
cpu_avg_samples = 2, --Усреднение значений нагрузки.
default_color = "#2bf92b", --Цвет по умолчанию.
double_buffer = true, --Включение двойной буферизации.
draw_shades = false, --Оттенки.
font = "Fantasque Sans Mono:size='"$(($font-2))"'", --Шрифт и размер шрифта.
gap_y = '"$(($font*5))"', --Отступ сверху.
gap_x = '"$(($font*2))"', --Отступ от края.
own_window = true, --Собственное окно.
own_window_class = "Conky", --Класс окна.
own_window_type = "override", --Тип окна.
--own_window_type = "desktop", --Тип окна.
own_window_hints = "undecorated, sticky, above, skip_taskbar, skip_pager", --Задаем эфекты отображения окна.
own_window_argb_visual = true, --Прозрачность окна.
own_window_argb_value = 150, --Уровень прозрачности.
use_xft = true, } --Использование шрифтов X сервера.
conky.text = [[ #Наполнение виджета.
#Блок "Часы".
${font Fantasque Sans Mono:size='"$(($font*2))"'}$alignc${color #f92b2b}$alignc${time %H:%M}$font$color
#Блок "Дата".
${font Fantasque Sans Mono:size='"$(($font+2))"'}$alignc${color #b2b2b2}${time %d %b %Y} (${time %a})$color$font
#Блок "Погода".
$alignc${execi 3600 curl wttr.in/?format=\047%l,+%t+(%f)\047}$font
#Блок "Система".
${color #f92b2b}SYS${hr 3}
${color #b2b2b2}Kernel:$color$alignr$kernel
${color #b2b2b2}PC works:$color$alignr$uptime
#Блок "ЦП".
${color #f92b2b}CPU${hr 3}
${color #b2b2b2}$cpu%$color$alignc${cpugraph '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t}$alignr$freq MHz'"${coremassconf[@]}"'
${color #b2b2b2}${hr 2}
${color #b2b2b2}Process ${color #f92b2b}$alignc PID $color$alignr Used
$color${hr 1}
${color #b2b2b2}${top name 1} ${color #f92b2b}$alignc ${top pid 1} $color$alignr ${top cpu 1}
${color #b2b2b2}${top name 2} ${color #f92b2b}$alignc ${top pid 2}$color$alignr ${top cpu 2}
${color #b2b2b2}${top name 3} ${color #f92b2b}$alignc ${top pid 3}$color$alignr ${top cpu 3}
${color #b2b2b2}${top name 4} ${color #f92b2b}$alignc ${top pid 4}$color$alignr ${top cpu 4}
${color #b2b2b2}${top name 5} ${color #f92b2b}$alignc ${top pid 5}$color$alignr ${top cpu 5}'"$fanconky"''"$nvidiac"'
#Блок "ОЗУ".
${color #f92b2b}RAM${hr 3}$color
$memperc% ${memgraph '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t} $alignr${color #f92b2b}$mem / $color$memeasyfree / ${color #b2b2b2}$memmax
${color #b2b2b2}${hr 2}
${color #b2b2b2}Process ${color #f92b2b}$alignc PID $color$alignr Used
$color${hr 1}
${color #b2b2b2}${top_mem name 1} ${color #f92b2b}$alignc ${top_mem pid 1} $color$alignr ${top_mem mem 1}
${color #b2b2b2}${top_mem name 2} ${color #f92b2b}$alignc ${top_mem pid 2}$color$alignr ${top_mem mem 2}
${color #b2b2b2}${top_mem name 3} ${color #f92b2b}$alignc ${top_mem pid 3}$color$alignr ${top_mem mem 3}
${color #b2b2b2}${top_mem name 4} ${color #f92b2b}$alignc ${top_mem pid 4}$color$alignr ${top_mem mem 4}
${color #b2b2b2}${top_mem name 5} ${color #f92b2b}$alignc ${top_mem pid 5}$color$alignr ${top_mem mem 5}
#Блок "Раздел подкачки".
${color #f92b2b}SWAP${hr 3}$color
$swapperc% ${swapbar '"$font"','"$(($font*6))"'} $alignr${color #f92b2b}$swap / $color$swapfree / ${color #b2b2b2}$swapmax
#Блок "Сеть".
${color #f92b2b}NET${hr 3}$color
${color #b2b2b2}IP:$alignr${curl eth0.me}$color↑${upspeedf '"$netdev"'} ${upspeedgraph '"$netdev"' '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t} $alignr↓${downspeedf '"$netdev"'} ${downspeedgraph '"$netdev"' '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t}
#Блок "Системный диск".
${color #f92b2b}HDD/SSD${hr 3}$color
${color #b2b2b2}${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}/root${hr 1}$color
(${fs_type /root})${fs_bar '"$font"','"$(($font*6))"' /root} $alignr${color #f92b2b}${fs_used /root} / $color${fs_free /root} / ${color #b2b2b2}${fs_size /root}
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}/var${hr 1}$color
(${fs_type /var})${fs_bar '"$font"','"$(($font*6))"' /var} $alignr${color #f92b2b}${fs_used /var} / $color${fs_free /var} / ${color #b2b2b2}${fs_size /var}
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}/home${hr 1}$color
(${fs_type /home})${fs_bar '"$font"','"$(($font*6))"' /home} $alignr${color #f92b2b}${fs_used /home} / $color${fs_free /home} / ${color #b2b2b2}${fs_size /home}'"${masslabel[@]}"'
]]' > /mnt/home/"$username"/.config/conky/conky.conf
#
#Создание конфига bash_profile (Настройка Xorg).
echo -e "\033[36mСоздание конфига bash_profile (Настройка Xorg).\033[0m"
echo '[[ -f ~/.profile ]] && . ~/.profile' | tee /mnt/home/"$username"/.bash_profile /mnt/root/.bash_profile
#
#Создание конфига bashrc (Настройка Xterm).
echo -e "\033[36mСоздание конфига bashrc (Настройка Xterm).\033[0m"
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
PS1="\[\e[48;2;249;43;43m\]\[\e[38;2;43;249;43m\] \$\[\e[48;2;249;249;43m\]\[\e[38;2;249;43;43m\]\[\e[48;2;249;249;43m\]\[\e[38;2;43;43;249m\]\A\[\e[48;2;43;43;249m\]\[\e[38;2;249;249;43m\] \u@\h\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;249m\]\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;43m\]\W\[\e[48;2;43;43;43m\]\[\e[0m\]\[\e[38;2;43;249;43m\] \[\e[0m\]"
#\[\e[48;2;249;43;43m\] - Красный цвет фона.
#\[\e[38;2;43;249;43m\] - Зеленый цвет шрифта.
#\$ - Символ приглашения (# для root, $ для обычных пользователей).
#\[\e[48;2;249;249;43m\] - Жёлтый цвет фона.
#\[\e[38;2;249;43;43m\] - Красный цвет шрифта.
#\[\e[48;2;249;249;43m\] - Жёлтый цвет фона.
#\[\e[38;2;43;43;249m\] - Синий цвет шрифта.
#\A - Текущее время в 24-часовом формате.
#\[\e[48;2;43;43;249m\] - Синий цвет фона.
#\[\e[38;2;249;249;43m\] - Жёлтый цвет шрифта.
#\u@\h - ИмяПользователя@ИмяХоста.
#\[\e[48;2;43;249;43m\] - Зеленый цвет фона.
#\[\e[38;2;43;43;249m\] - Синий цвет шрифта.
#\[\e[48;2;43;249;43m\] - Зеленый цвет фона.
#\[\e[38;2;43;43;43m\] - Серый цвет шрифта.
#\W - ТекущийОтносительныйПуть.
#\[\e[48;2;43;43;43m\] - Серый цвет фона.
#\[\e[0m\] - Конец изменениям.
#\[\e[38;2;43;249;43m\] - Зеленый цвет шрифта.
#\[\e[0m\] - Конец изменениям.
#Удаляем повторяющиеся записи и записи начинающиеся с пробела (например команды в mc) в .bash_history.
export HISTCONTROL="ignoreboth"
export COLORTERM=truecolor #Включаем все 16 миллионов цветов в эмуляторе терминала.' | tee /mnt/home/"$username"/.bashrc /mnt/root/.bashrc
#
#Создание конфига profile (Настройка Xorg).
echo -e "\033[36mСоздание конфига profile (Настройка Xorg).\033[0m"
echo '[[ -f ~/.bashrc ]] && . ~/.bashrc #Указание на bashrc.
export QT_QPA_PLATFORMTHEME=gnome #Изменение внешнего вида приложений использующих qt.
export QT_STYLE_OVERRIDE=adwaita-dark #Использовать Adwaitа в качестве стиля Qt по умолчанию' | tee /mnt/home/"$username"/.profile /mnt/root/.profile
#
#Создание конфига сервера уведомлений.
echo -e "\033[36mСоздание конфига сервера уведомлений.\033[0m"
echo '[global]
    gap_size = '"$font"'
    enable_posix_regex = true
    enable_recursive_icon_lookup = true
    icon_theme = ePapirus-Dark
[urgency_low]
    background = "#2b2b2b"
    foreground = "#b2b2b2"
    timeout = 10
[urgency_normal]
    background = "#2b2b2b"
    foreground = "#2bf92b"
    timeout = 10
[urgency_critical]
    background = "#2b2b2b"
    foreground = "#f92b2b"
    timeout = 0' > /mnt/etc/dunst/dunstrc
#
#Создание конфига picom (Автономный композитор для Xorg).
echo -e "\033[36mСоздание конфига picom (Автономный композитор для Xorg).\033[0m"
echo -e '# Прозрачность активных окон (0,1–1,0).
active-opacity = 0.95;
#
# Прозрачность неактивных окон (0,1–1,0).
inactive-opacity = 0.9;
#
# Затемнение неактивных окон (0,0–1,0).
inactive-dim = 0.65;
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
opacity-rule = [ "90:class_g = \047i3bar\047",
                 "90:class_g = \047dmenu\047",
                 "80:class_g = \047XTerm\047",
                 "100:class_g = \047vlc\047",
                 "100:fullscreen" ];
#
#Закругленные углы.
corner-radius = '"$font"';
rounded-corners-exclude = [ "window_type = \047dock\047",
                            "window_type = \047popup_menu\047",
                            "window_type = \047dropdown_menu\047",
                            "window_type = \047notification\047" ];
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
#TechnicalSymbol                            "window_type = \047tooltip\047",
#TechnicalSymbol                            "class_g = \047Conky\047",
#TechnicalSymbol                            "class_g = \047i3bar\047",
#TechnicalSymbol                            "class_g = \047vlc\047",
#TechnicalSymbol                            "_NET_WM_STATE@:a != \047_NET_WM_STATE_FOCUSED\047" ];
' > /mnt/home/"$username"/.config/picom.conf
#
#Создание конфига xresources (Настройка Xorg).
echo -e "\033[36mСоздание конфига xresources (Настройка Xorg).\033[0m"
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
!Цвет фона.
xterm*background: #2b2b2b
!
!Цвет шрифта.
xterm*foreground: #2bf92b
!
!Цвет курсора.
xterm*cursorColor: #f92b2b
!
!Мерцание курсора.
xterm*cursorBlink: true
!
!Указывает, должна ли отображаться полоса прокрутки.
xterm*scrollBar: false
!
!Указывает, должно ли нажатие клавиши автоматически перемещать полосу прокрутки в нижнюю часть области прокрутки.
xterm*scrollKey: true
!
!Размер курсора.
Xcursor.size: '"$(($font*3))"'
Xcursor.theme: Adwaita' | tee /mnt/home/"$username"/.Xresources /mnt/root/.Xresources
#
#Создание директории и конфига i3-wm (Тайловый оконный менеджер).
echo -e "\033[36mСоздание конфига i3-wm (Тайловый оконный менеджер).\033[0m"
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
set $ws1 "1: ⛏️"
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
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m \047Вы действительно хотите выйти из i3? Это завершит вашу сессию X.\047 -b \047Да, выйти из i3\047 \047i3-msg exit\047"
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
# Включить плавающий режим для всех окон gogglesmm.
for_window [class="gogglesmm"] floating enable
#
########### Автозапуск программ ###########
#
# Приветствие в течении 10 сек (--no-startup-id убирает курсор загрузки).
exec --no-startup-id notify-send -te 10000 "✊Доброго времени суток✊" "ЛКМ на кнопке 🛈 -- Шпаргалка по i3wm.";
#
# Автозапуск conky.
exec --no-startup-id conky;
#
# Автозапуск lxqt-panel.
exec --no-startup-id lxqt-panel;
#
# Автозапуск picom.
exec --no-startup-id picom -b;
#
# Запуск графического интерфейса системного трея NetworkManager.
exec --no-startup-id nm-applet;
#
# Запуск геолокации.
exec --no-startup-id /usr/lib/geoclue-2.0/demos/agent;
#
# Автозапуск flameshot.
exec --no-startup-id flameshot;
#
# Автозапуск copyq и autocutsel.
exec --no-startup-id copyq;
exec --no-startup-id autocutsel;
#
# Автозапуск dolphin.
exec --no-startup-id dolphin --daemon;
#
# Автоматическая разблокировка KWallet.
exec --no-startup-id /usr/lib/pam_kwallet_init;
#
# Автозапуск gogglesmm.
exec --no-startup-id gogglesmm --tray;
#
# Автозапуск blueman.
exec --no-startup-id blueman-applet;
#
# Автозапуск smb4k.
exec --no-startup-id smb4k;
#
# Автозапуск usbguard.
exec --no-startup-id sudo -E usbguard-applet-qt;
#
# Автозапуск .
exec --no-startup-id sh -c \047sleep 10; while [[ -z "$(ls /dev/pts/2)" ]]; do sleep 5; done;sleep 5; neofetch > /dev/pts/2;\047
#
# Автозапуск neofetch и обновления.
#TechnicalSymbolexec --no-startup-id sh -c \047sleep 10; while [[ 1 -ge "$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)" ]]; do sleep 5; done; sleep 5; pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-2)}\047\\\047\047)"; neofetch > /dev/pts/$pts; pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)"; sudo rm /var/lib/pacman/db.lck > /dev/pts/$pts; sudo pacman -Suy --noconfirm > /dev/pts/$pts; sudo pacman -Sc --noconfirm > /dev/pts/$pts; sudo pacman -Rsn $(pacman -Qdtq) --noconfirm > /dev/pts/$pts\047
#
# Автозапуск numlockx.
exec --no-startup-id numlockx;
#
# Автозапуск steam.
exec --no-startup-id ENABLE_VKBASALT=1 gamemoderun steam -silent %U;
#
########### Горячие клавиши запуска программ ###########
#
#Восстановление рабочего стола №1.
bindsym $mod+mod1+1 exec --no-startup-id "i3-msg \047workspace 1: ⛏️; append_layout ~/.config/i3/workspace_1.json; exec xterm; exec xterm; exec dolphin; exec xed\047"
exec --no-startup-id "i3-msg \047workspace 1: ⛏️; append_layout ~/.config/i3/workspace_1.json; exec xterm; exec xterm; exec dolphin; exec xed\047"
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
        font pango:Fantasque Sans Mono '"$font"'
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
exec --no-startup-id firefox; #TechnicalString
exec --no-startup-id ~/archinstall.sh; #TechnicalString' > /mnt/home/"$username"/.config/i3/config
#
#Создание конфига i3status (Панель рабочего стола i3-wm (Тайловый оконный менеджер)).
echo -e "\033[36mСоздание конфига i3status (Панель рабочего стола i3-wm (Тайловый оконный менеджер)).\033[0m"
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
order += "cpu_usage" #5 модуль - использование ЦП.
order += "cpu_temperature 0" #6 модуль - температура ЦП.
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
cpu_usage { #Использование ЦП.
    format = "🧠: %usage/"
    separator_block_width = 0 } #Формат вывода.
cpu_temperature 0 { #Температура ЦП.
    format = "%degrees°C" #Формат вывода.
    max_threshold = "70" #Красный порог.
    format_above_threshold = "%degrees°C" #Формат вывода красного порога.
    path = "/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input" } #Путь данных.path: /sys/devices/platform/coretemp.0/temp1_input
tztime 0 { #Вывод разделителя.
    format = "|" } #Формат вывода.' | tee /mnt/home/"$username"/.i3status.conf /mnt/root/.i3status.conf
#
#Создание конфига redshift (Регулирует цветовую температуру вашего экрана).
echo -e "\033[36mСоздание конфига redshift (Регулирует цветовую температуру вашего экрана).\033[0m"
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
#Настройка polkit (Фреймворк для управления общесистемными привилегиями) для блютуз.
echo -e "\033[36mНастройка polkit (Фреймворк для управления общесистемными привилегиями) для блютуз.\033[0m"
echo 'polkit.addRule(function(action, subject) {
    if ((action.id == "org.blueman.network.setup" ||
         action.id == "org.blueman.dhcp.client" ||
         action.id == "org.blueman.rfkill.setstate" ||
         action.id == "org.blueman.pppd.pppconnect") &&
        subject.isInGroup("wheel")) {

        return polkit.Result.YES;
    }
});' > /mnt/etc/polkit-1/rules.d/51-blueman.rules
#
#Настройка polkit (Фреймворк для управления общесистемными привилегиями) для принтеров.
echo -e "\033[36mНастройка polkit (Фреймворк для управления общесистемными привилегиями) для принтеров.\033[0m"
echo 'polkit.addRule(function(action, subject) {
    if (action.id == "org.opensuse.cupspkhelper.mechanism.all-edit" &&
        subject.isInGroup("wheel")){
        return polkit.Result.YES;
    }
});' > /mnt/etc/polkit-1/rules.d/49-allow-passwordless-printer-admin.rules
#
#Настройка pam_kwallet.
echo -e "\033[36mНастройка pam_kwallet.\033[0m"
echo 'auth optional pam_kwallet5.so
session optional pam_kwallet5.so auto_start' >> /mnt/etc/pam.d/xdm
#
#Создание конфига рабочего стола №1.
echo -e "\033[36mСоздание конфига рабочего стола №1.\033[0m"
echo '{
    "border": "normal",
    "current_border_width": 1,
    "floating": "auto_off",
    "percent": 0.5,
    "swallows": [
       { "class": "^Xed$" }
    ]
}
{
    "border": "normal",
    "layout": "splitv",
    "percent": 0.5,
    "type": "con",
    "nodes": [
        {
            "border": "normal",
            "current_border_width": 1,
            "floating": "auto_off",
            "percent": 0.6,
            "swallows": [
               { "class": "^dolphin$" }
            ]
        },
        {
            "border": "normal",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 0.4,
            "type": "con",
            "nodes": [
                {
                    "border": "normal",
                    "current_border_width": 1,
                    "floating": "user_off",
                    "percent": 0.5,
                    "swallows": [
                       {
                        "class": "^XTerm$",
                        "title": "'"$username"'\\@'"$hostname"'\\:\\~$"
                       }
                    ]
                },
                {
                    "border": "normal",
                    "current_border_width": 1,
                    "floating": "user_off",
                    "percent": 0.5,
                    "swallows": [
                       {
                        "class": "^XTerm$",
                        "title": "'"$username"'\\@'"$hostname"'\\:\\~$"
                       }
                    ]
                }
            ]
        }
    ]
}' > /mnt/home/"$username"/.config/i3/workspace_1.json
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
🚀 -- Включить/Выключить визуальные эффекты.
#
🛈 -- Информация о системе.
#
✖ -- Выход пользователя.
#
⭯ -- Перезагрузить ПК.
#
⏻ -- Выключить ПК.
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
#Создание директории и конфига gtk (Внешний вид gtk программ).
echo -e "\033[36mСоздание конфига gtk (Внешний вид gtk программ).\033[0m"
mkdir -p /mnt/home/"$username"/.config/{gtk-3.0,gtk-4.0} /mnt/root/.config/{gtk-3.0,gtk-4.0}
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=Adwaita
gtk-font-name=Fantasque Sans Mono Bold Italic '"$font"'
gtk-icon-theme-name=ePapirus-Dark
gtk-theme-name=Adwaita-dark' | tee /mnt/home/"$username"/.config/gtk-3.0/settings.ini /mnt/home/"$username"/.config/gtk-4.0/settings.ini /mnt/root/.config/gtk-3.0/settings.ini /mnt/root/.config/gtk-4.0/settings.ini
echo 'gtk-application-prefer-dark-theme="true"
gtk-cursor-theme-name="Adwaita"
gtk-font-name="Fantasque Sans Mono Bold Italic '"$font"'"
gtk-icon-theme-name="ePapirus-Dark"
gtk-theme-name="Adwaita-dark"' > /mnt/usr/share/gtk-2.0/gtkrc
#
#Создание директории и конфига lxqt-panel (Панель рабочего стола LXQt).
echo -e "\033[36mСоздание конфига lxqt-panel (Панель рабочего стола LXQt).\033[0m"
mkdir -p /mnt/home/"$username"/.config/lxqt
echo '[General]
__userfile__=true
iconTheme=ePapirus-Dark
[customcommand]
alignment=Right
click="sh -c \"x=pidof picom; if [ -n x ]; then killall picom; else picom -b; fi\""
command=echo \xd83d\xde80
maxWidth='"$(($font*3))"'
type=customcommand
[customcommand2]
alignment=Right
click="sh -c \"sed -i \047s/own_window_type/--own_window_type/\047 ~/.config/conky/conky.conf; sed -i \047s/----//\047 ~/.config/conky/conky.conf\""
command=echo \xd83d\xdec8
maxWidth='"$(($font*3))"'
type=customcommand
[customcommand3]
alignment=Right
click=xed /help.txt
command=echo \x2753
maxWidth='"$(($font*3))"'
type=customcommand
[customcommand4]
alignment=Right
click="sh -c \"i3-nagbar -t warning -m \047\x412\x44b \x434\x435\x439\x441\x442\x432\x438\x442\x435\x43b\x44c\x43d\x43e \x445\x43e\x442\x438\x442\x435 \x432\x44b\x439\x442\x438 \x438\x437 i3? \x42d\x442\x43e \x437\x430\x432\x435\x440\x448\x438\x442 \x432\x430\x448\x443 \x441\x435\x441\x441\x438\x44e X.\047 -b \047\x414\x430, \x432\x44b\x439\x442\x438 \x438\x437 i3\047 \047i3-msg exit\047\""
command=echo \x2716
maxWidth='"$(($font*3))"'
type=customcommand
[customcommand5]
alignment=Right
click=reboot
command=echo \x2b6f
maxWidth='"$(($font*3))"'
type=customcommand
[customcommand6]
alignment=Right
click=poweroff
command=echo \x23fb
maxWidth='"$(($font*3))"'
type=customcommand
[kbindicator]
alignment=Right
keeper_type=window
show_caps_lock=true
show_layout=true
show_num_lock=true
show_scroll_lock=true
type=kbindicator
[mainmenu]
alignment=Left
filterClear=true
icon=/usr/share/icons/ePapirus-Dark/16x16/apps/distributor-logo-archlinux.svg
menu_file=/etc/xdg/menus/arch-applications.menu
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
iconSize='"$(($font*3))"'
lineCount=1
lockPanel=false
opacity=90
panelSize='"$(($font*3))"'
plugins=mainmenu, spacer, quicklaunch, kbindicator, worldclock, volume, customcommand, customcommand2, customcommand3, customcommand4, customcommand5, customcommand6
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
type=volume
[worldclock]
alignment=Right
autoRotate=true
customFormat="\047<b>\047HH:mm:ss\047</b><br/><font size=\"-2\">\047ddd, d MMM yyyy\047<br/>\047TT\047</font>\047"
dateFormatType=custom
dateLongNames=false
datePadDay=false
datePosition=below
dateShowDoW=false
dateShowYear=false
defaultTimeZone=
formatType=long-timeonly
showDate=false
showTimezone=false
showTooltip=false
showWeekNumber=true
timeAMPM=false
timePadHour=true
timeShowSeconds=true
timeZones\size=0
timezoneFormatType=iana
timezonePosition=below
type=worldclock
useAdvancedManualFormat=false' > /mnt/home/"$username"/.config/lxqt/panel.conf
#
#Создание конфига kdeglobals (Внешний вид kde программ).
echo -e "\033[36mСоздание конфига kdeglobals (Внешний вид kde программ).\033[0m"
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
ForegroundInactive=178,178,178' | tee /mnt/home/"$username"/.config/kdeglobals /mnt/root/.config/kdeglobals
#
#Создание пользовательских директорий.
echo -e "\033[36mСоздание пользовательских директорий.\033[0m"
mkdir -p /mnt/home/"$username"/Documents/{Downloads,Public,Desktop,Music,Pictures,Templates,Videos} /mnt/root/Documents/{Downloads,Public,Desktop,Music,Pictures,Templates,Videos}
#
#Создание конфига samba (Стандартный набор программ взаимодействия Windows для Linux и Unix).
mkdir -p /mnt/home/"$username"/Documents/Public/{Out,In}
echo -e "\033[36mСоздание конфига samba (Стандартный набор программ взаимодействия Windows для Linux и Unix).\033[0m"
echo '[global]
workgroup = WORKGROUP
security = user
map to guest = bad user
wins support = no
dns proxy = no
usershare path = /var/lib/samba/usershares
usershare max shares = 100
usershare allow guests = yes
usershare owner only = yes
[private]
path = /home/'"$username"'/Documents/Public/Out/
valid users = @wheel
guest ok = no
browsable = yes
writable = yes' > /mnt/etc/samba/smb.conf
#
#Создание конфига smb4krc (браузер общих ресурсов Samba (SMB/CIFS)).
echo -e "\033[36mСоздание конфига smb4krc (браузер общих ресурсов Samba (SMB/CIFS)).\033[0m"
echo '[Mounting]
DetectAllShares=true
MountPrefix=file:///home/'"$username"'/Documents/Public/In
RemountShares=true
UnmountSharesOnExit=true
[Network]
EnableWakeOnLAN=true
ForceSmb1Protocol=true
PreviewHiddenItems=true
[UserInterface]
StartMainWindowDocked=true' >> /mnt/home/"$username"/.config/smb4krc
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
curl -o /mnt/usr/share/fonts/google/SC.zip https://fonts.google.com/download?family=Noto%20Serif%20SC
arch-chroot /mnt unzip -o /usr/share/fonts/google/SC.zip -d /usr/share/fonts/google
rm /mnt/usr/share/fonts/google/*.zip
rm /mnt/usr/share/fonts/google/*.txt
#
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
#Настройка удаленного рабочего стола.
echo -e "\033[36mНастройка удаленного рабочего стола.\033[0m"
arch-chroot /mnt x11vnc -storepasswd $passuser /etc/x11vnc.pass
chmod ugo+r /mnt/etc/x11vnc.pass
echo '[Unit]
Description="x11vnc"
Requires=display-manager.service
After=display-manager.service
[Service]
ProtectSystem=full
ProtectHome=true
PrivateDevices=true
NoNewPrivileges=true
PrivateTmp=true
ExecStart=
ExecStart=x11vnc -many -rfbauth /etc/x11vnc.pass -env FD_XDM=1 -auth guess
[Install]
WantedBy=graphical.target' > /mnt/etc/systemd/system/x11vnc.service
#
#Установка помощника yay для работы с AUR (Репозиторий пользователей).
echo -e "\033[36mУстановка помощника yay для работы с AUR (Репозиторий пользователей).\033[0m"
arch-chroot /mnt/ sudo -u "$username" sh -c 'cd /home/'"$username"'/
git clone https://aur.archlinux.org/yay.git
cd /home/'"$username"'/yay
BUILDDIR=/tmp/makepkg makepkg -i --noconfirm'
rm -Rf /mnt/home/"$username"/yay
#
#Установка программ из AUR (Репозиторий пользователей).
echo -e "\033[36mУстановка программ из AUR (Репозиторий пользователей).\033[0m"
arch-chroot /mnt sudo -u "$username" yay -S gtk3-classic hardinfo debtap hunspell-ru-aot hyphen-ru mythes-ru minq-ananicy-git auto-cpufreq kde-cdemu-manager usbguard-applet-qt vkbasalt kmscon qgnomeplatform-qt5-git --noconfirm --ask 4
#
#Автозапуск служб.
echo -e "\033[36mАвтозапуск служб.\033[0m"
arch-chroot /mnt systemctl disable dbus getty@tty1.service
arch-chroot /mnt systemctl enable acpid bluetooth fancontrol NetworkManager reflector.timer xdm-archlinux dhcpcd avahi-daemon ananicy haveged dbus-broker rngd auto-cpufreq smartd smb saned.socket cups.socket x11vnc ufw auditd ntpd kmsconvt@tty1.service
#
#Настройка звука.
echo -e "\033[36mНастройка звука.\033[0m"
sed -i 's/; resample-method = speex-float-1/resample-method = src-sinc-best-quality/' /mnt/etc/pulse/daemon.conf
#
#Создание скрипта, который после перезагрузки продолжит установку.
echo -e "\033[36mСоздание скрипта, который после перезагрузки продолжит установку.\033[0m"
echo -e '#!/bin/bash
sleep 10
nmcli device wifi connect "'"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f" | sed s/.psk//)"'" password "'"$(grep Passphrase= /var/lib/iwd/"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f")" | sed s/Passphrase=//)"'"
echo -e "\033[36mЗавершение установки.\033[0m" > /dev/pts/1
#
#Счетчик.
while [[ -z "$(xwininfo -root -tree | grep -i firefox | grep -i mozilla)" ]]; do
    echo "\033[31mПродолжение установки!\033[0m" > /dev/pts/1
    sleep 5
done
sleep 10
#
#Обнаружение кулеров.
echo -e "\033[36mОбнаружение кулеров.\033[0m"
sudo sensors-detect --auto > /dev/pts/1
#
#Настройка браузера.
echo -e "\033[36mНастройка браузера.\033[0m"
ls ~/.mozilla/firefox/*.default-release
echo -e \047user_pref("layout.css.devPixelsPerPx", "'"$fox"'");
user_pref("accessibility.typeaheadfind", true);
user_pref("intl.regional_prefs.use_os_locales", true);
user_pref("widget.gtk.overlay-scrollbars.enabled", false);
user_pref("browser.startup.page", 3);
user_pref("browser.download.useDownloadDir", false);\047 > $_/user.js
#
#Настройка picom (Автономный композитор для Xorg).
echo -e "\033[36mНастройка picom (Автономный композитор для Xorg).\033[0m"
if [ -n "$(clinfo -l)" ];
    then sed -i \047s/#TechnicalSymbol //\047 ~/.config/picom.conf
    else sed -i \047/#TechnicalSymbol /d\047 ~/.config/picom.conf
fi
#
#Настройка звука.
echo -e "\033[36mНастройка звука.\033[0m"
soundmass=($(pacmd list-sinks | grep -i name: | awk \047{print $2}\047))
for (( j=0, i=1; i<="${#soundmass[*]}"; i++, j++ ))
            do
amixer -c "$j" sset Master unmute > /dev/pts/1
amixer -c "$j" sset Speaker unmute > /dev/pts/1
amixer -c "$j" sset Headphone unmute > /dev/pts/1
amixer -c "$j" sset "Auto-Mute Mode" Disabled > /dev/pts/1
amixer -c "$j" sset "HP/Speaker Auto Detect" unmute > /dev/pts/1
            done
alsactl store
#
#Настройка внешнего вида программ.
echo -e "\033[36mНастройка внешнего вида программ.\033[0m"
gsettings set org.gnome.desktop.interface icon-theme ePapirus-Dark
gsettings set org.gnome.desktop.interface font-name \047Fantasque Sans Mono, '"$font"'\047
gsettings set org.gnome.desktop.interface document-font-name \047Fantasque Sans Mono Bold Italic '"$font"'\047
gsettings set org.gnome.desktop.interface monospace-font-name \047Fantasque Sans Mono '"$font"'\047
gsettings set org.gnome.desktop.wm.preferences titlebar-font \047Fantasque Sans Mono Bold '"$font"'\047
gsettings set org.gnome.libgnomekbd.indicator font-size '"$font"'
gsettings set org.gnome.meld custom-font \047monospace, '"$font"'\047
#
#Проверка наличия touchpad.
echo -e "\033[36mПроверка наличия touchpad.\033[0m"
if [ -n "$(xinput list | grep -i touchpad)" ]; then
sudo pacman -S xf86-input-libinput --noconfirm > /dev/pts/1
sudo tee -a /etc/X11/xorg.conf.d/00-keyboard.conf <<< \047
Section "InputClass"
Identifier "libinput touchpad catchall"
MatchIstouchpad "on"
MatchDevicePath "/dev/input/event*"
Driver "libinput"
Option "Tapping" "on"
EndSection\047
fi
#
#Настройка брандмауэра.
echo -e "\033[36mНастройка брандмауэра.\033[0m"
sudo ufw default deny
sudo ufw allow from 192.168.0.0/24
sudo ufw allow Deluge
sudo ufw limit ssh
sudo ufw allow 5900
sudo ufw allow 5353
sudo ufw enable
sudo sed -i \047s/#net\/ipv4\/ip_forward=1/net\/ipv4\/ip_forward=1/\047 /etc/ufw/sysctl.conf
sudo sed -i \047s/#net\/ipv6\/conf\/default\/forwarding=1/net\/ipv6\/conf\/default\/forwarding=1/\047 /etc/ufw/sysctl.conf
sudo sed -i \047s/#net\/ipv6\/conf\/all\/forwarding=1/net\/ipv6\/conf\/all\/forwarding=1/\047 /etc/ufw/sysctl.conf
#
#Установка переменных окружения.
echo -e "\033[36mУстановка переменных окружения.\033[0m"
sudo sh -c \047echo "ENABLE_VKBASALT=1
GTK_USE_PORTAL=1" >> /etc/environment\047
#
#Настройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).
echo -e "\033[36mНастройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).\033[0m"
sudo usbguard generate-policy > /etc/usbguard/rules.conf
sudo systemctl enable usbguard
sudo systemctl start usbguard
#
#Включение службы redshift (Регулирует цветовую температуру вашего экрана).
echo -e "\033[36mВключение службы redshift (Регулирует цветовую температуру вашего экрана).\033[0m"
systemctl --user enable redshift-gtk
systemctl --user start redshift-gtk
#
#Настройка wine (Позволяет запускать приложения Windows).
echo -e "\033[36mНастройка wine (Позволяет запускать приложения Windows).\033[0m"
WINEARCH=win32 winetricks d3dx9 vkd3d vcrun6 mfc140 dxvk dotnet48 allcodecs > /dev/pts/1
#
#Удаление временных файлов.
echo -e "\033[36mУдаление временных файлов.\033[0m"
sed -i \047/#TechnicalString/d\047 ~/.config/i3/config
sed -i \047s/#TechnicalSymbol//\047 ~/.config/i3/config
rm ~/archinstall.sh' > /mnt/home/"$username"/archinstall.sh
#
#Передача прав созданному пользователю.
echo -e "\033[36mПередача прав созданному пользователю.\033[0m"
arch-chroot /mnt chown -R "$username" /home/"$username"/
#
#Настройка samba (Стандартный набор программ взаимодействия Windows для Linux и Unix).
echo -e "\033[36mНастройка samba (Стандартный набор программ взаимодействия Windows для Linux и Unix).\033[0m"
mkdir /mnt/var/lib/samba/usershares
arch-chroot /mnt groupadd -r sambashare
arch-chroot /mnt chown root:sambashare /var/lib/samba/usershares
arch-chroot /mnt chmod 1770 /var/lib/samba/usershares
arch-chroot /mnt gpasswd sambashare -a "$username"
#
#Настройка virtualbox учитывая хост/гость.
echo -e "\033[36mНастройка virtualbox учитывая хост/гость.\033[0m"
if [ -n "$(lspci | grep -i vga | grep -iE 'vmware svga|virtualbox')" ]; then
echo "vboxguest
vboxsf
vboxvideo" > /mnt/etc/modules-load.d/virtualboxguest.config
arch-chroot /mnt systemctl enable vboxservice
sed -i 's/exec i3 #Автозапуск i3./\/usr\/sbin\/VBoxClient-all \&\nexec i3 #Автозапуск i3./' /mnt/home/"$username"/.xinitrc
arch-chroot /mnt gpasswd -a "$username" vboxsf
else
arch-chroot /mnt pacman -Sy virtualbox-host-dkms --noconfirm
arch-chroot /mnt sudo -u "$username" yay -S virtualbox-ext-oracle --noconfirm
echo "vboxdrv
vboxnetflt
vboxnetadp" > /mnt/etc/modules-load.d/virtualboxhosts.config
arch-chroot /mnt gpasswd -a "$username" vboxusers
fi
#
#Undervolting CPU (Снижение напряжения ЦП на 10%).
echo -e "\033[36mUndervolting CPU (Снижение напряжения ЦП на 10%).\033[0m"
if [ -n "$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)" ]; then
echo '[charger]
scaling_max_freq = '$(("$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq)"/100*90))'' > /mnt/etc/auto-cpufreq.conf
fi
#
#Ограничение на размер дампа.
echo -e "\033[36mОграничение на размер дампа.\033[0m"
echo "* hard core 0" >> /mnt/etc/security/limits.conf
#
#Настройка прав: Только пользователь создатель имеет разрешения на чтение, запись и выполнение.
echo -e "\033[36mНастройка прав: Только пользователь создатель имеет разрешения на чтение, запись и выполнение.\033[0m"
sed -i 's/umask 022/umask 077/' /mnt/etc/profile
#
#Настройка разрешения локального имени хоста.
echo -e "\033[36mНастройка разрешения локального имени хоста.\033[0m"
sed -i 's/mymachines/mymachines mdns_minimal [NOTFOUND=return]/' /mnt/etc/nsswitch.conf
#
#Обновление часового пояса после подключения к сети через NetworkManager.
echo -e "\033[36mОбновление часового пояса после подключения к сети через NetworkManager.\033[0m"
echo '#!/bin/sh
case "$2" in
    up)
        timedatectl set-timezone "$(curl --fail https://ipapi.co/timezone)"
    ;;
esac' > /mnt/etc/NetworkManager/dispatcher.d/09-timezone
#
#Делаем xinitrc, 09-timezone и archinstall.sh исполняемыми.
echo -e "\033[36mДелаем xinitrc, 09-timezone и archinstall.sh исполняемыми.\033[0m"
chmod +x /mnt/etc/NetworkManager/dispatcher.d/09-timezone /mnt/home/"$username"/.xinitrc /mnt/home/"$username"/archinstall.sh /mnt/root/.xinitrc
#
#Удаленное включение компьютера с помощью Wake-on-LAN (WOL).
echo -e "\033[36mУдаленное включение компьютера с помощью Wake-on-LAN (WOL).\033[0m"
arch-chroot /mnt ethtool -s "$netdev" wol g
#
#Добавление правил auditd (Аудит доступа к основным файлам общей безопасности).
echo -e "\033[36mДобавление правил auditd (Аудит доступа к основным файлам общей безопасности).\033[0m"
echo '-w /etc/group -p wa
-w /etc/passwd -p wa
-w /etc/shadow -p wa
-w /etc/sudoers -p wa' > /mnt/etc/audit/rules.d/rules.rules
#
#Создание конфига xdg-user-dirs (Пользовательские директории).
echo -e "\033[36mСоздание конфига xdg-user-dirs (Пользовательские директории).\033[0m"
echo 'XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_DOWNLOAD_DIR="$HOME/Documents/Downloads"
XDG_PUBLICSHARE_DIR="$HOME/Documents/Public"
XDG_DESKTOP_DIR="$HOME/Documents/Desktop"
XDG_MUSIC_DIR="$HOME/Documents/Music"
XDG_PICTURES_DIR="$HOME/Documents/Pictures"
XDG_TEMPLATES_DIR="$HOME/Documents/Templates"
XDG_VIDEOS_DIR="$HOME/Documents/Videos"' | tee /mnt/home/"$username"/.config/user-dirs.dirs /mnt/root/.config/user-dirs.dirs
#
#Ограничение прав к ключям ssh.
echo -e "\033[36mОграничение прав к ключям ssh.\033[0m"
chmod 600 /mnt/etc/ssh/sshd_config
#
#Установка завершена, после перезагрузки вас встретит настроенная и готовая к работе ОС.
echo -e "\033[36mУстановка завершена, после перезагрузки скрипт продолжит установку.\033[0m"
while [[ 0 -ne $tic ]]; do
    echo -e "\033[31m...\033[36m$tic\033[31m...\033[0m"
    sleep 1
    tic=$(($tic-1))
done
umount -R /mnt
reboot
