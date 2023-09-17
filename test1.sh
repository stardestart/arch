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
#gpg --refresh-keys
pacman-key --init
pacman-key --populate archlinux
pacman --color always -Sy gnupg --noconfirm
pacman --color always -Sy archlinux-keyring --noconfirm
#pacman --color always -Syy openssh --noconfirm
pacman --color always -Sy reflector usbguard sad coreutils --noconfirm
reflector --latest 20 --protocol https --sort rate --download-timeout 2 --save /etc/pacman.d/mirrorlist
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
#
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
        arch-chroot /mnt pacman --color always -Sy grub --noconfirm
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
        arch-chroot /mnt pacman --color always -Sy efibootmgr --noconfirm
        arch-chroot /mnt bootctl install
        echo -e "default arch\ntimeout 2\neditor yes\nconsole-mode max" > /mnt/boot/loader/loader.conf
        echo -e "title Arch Linux\nlinux /vmlinuz-linux-zen"$microcode"\ninitrd /initramfs-linux-zen.img\noptions root=/dev/"$sysdisk""$p3" rw\noptions resume=/dev/"$sysdisk""$p2"" > /mnt/boot/loader/entries/arch.conf
fi
#
#Установка микроинструкции для процессора.
echo -e "\033[36mУстановка микроинструкций для процессора.\033[0m"
if [ "$microcode" = "\ninitrd /amd-ucode.img" ]; then arch-chroot /mnt pacman --color always -Sy amd-ucode --noconfirm
elif [ "$microcode" = "\ninitrd /intel-ucode.img" ]; then arch-chroot /mnt pacman --color always -Sy intel-ucode iucode-tool --noconfirm
fi
#
#Настройка установщика pacman.
echo -e "\033[36mНастройка установщика pacman.\033[0m"
sed -i "s/#Color/Color/" /mnt/etc/pacman.conf
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
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
        arch-chroot /mnt pacman --color always -Sy nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia opencv-cuda nvtop cuda --noconfirm
        sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf
    else
        arch-chroot /mnt pacman --color always -Sy xf86-video-nouveau --noconfirm
        sed -i 's/MODULES=()/MODULES=(nouveau)/' /mnt/etc/mkinitcpio.conf
    fi
elif [ -n "$(lspci | grep -i vga | grep -iE 'vmware svga|virtualbox')" ]; then
    arch-chroot /mnt pacman --color always -Sy virtualbox-guest-utils --noconfirm
    sed -i 's/MODULES=()/MODULES=(vmwgfx vboxvideo vboxguest)/' /mnt/etc/mkinitcpio.conf
elif [ -n "$(lspci | grep -i vga | grep AMD)" ]; then
    arch-chroot /mnt pacman --color always -Sy xf86-video-ati xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon --noconfirm
    sed -i 's/MODULES=()/MODULES=(amdgpu radeon)/' /mnt/etc/mkinitcpio.conf
elif [ -n "$(lspci | grep -i vga | grep -i intel)" ]; then
    arch-chroot /mnt pacman --color always -Sy vulkan-intel intel-media-driver libva-intel-driver --noconfirm
    sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
fi
#Установка компонентов и программ ОС.
echo -e "\033[36mУстановка компонентов и программ ОС.\033[0m"
arch-chroot /mnt pacman --color always -Sy xorg xorg-xinit xterm i3-gaps i3status perl-anyevent-i3 perl-json-xs dmenu xdm-archlinux firefox flatpak xdg-desktop-portal-gtk network-manager-applet networkmanager-strongswan wireless_tools krdc blueman bluez bluez-utils bluez-qt git mc htop nano dhcpcd imagemagick acpid clinfo avahi reflector go libnotify autocutsel openssh haveged dbus-broker x11vnc polkit kwalletmanager kwallet-pam xlockmore xautolock gparted ark ntfs-3g dosfstools unzip smartmontools dolphin kdf filelight ifuse usbmuxd libplist libimobiledevice curlftpfs samba kimageformats ffmpegthumbnailer kdegraphics-thumbnailers qt5-imageformats kdesdk-thumbnailers ffmpegthumbs kdenetwork-filesharing smb4k papirus-icon-theme picom redshift lxqt-panel grc flameshot dunst gnome-themes-extra archlinux-wallpaper feh conky freetype2 ttf-fantasque-sans-mono neofetch alsa-utils alsa-plugins lib32-alsa-plugins alsa-firmware alsa-card-profiles pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol-qt aspell nuspell xed audacity cheese aspell-en aspell-ru ethtool pinta vlc libreoffice-still-ru hunspell hunspell-en_us hyphen hyphen-en libmythes mythes-en gimagereader-gtk  tesseract-data-rus  tesseract-data-eng kalgebra copyq kamera gwenview xreader gogglesmm sane skanlite nss-mdns cups-pk-helper cups cups-pdf system-config-printer steam wine winetricks wine-mono wine-gecko gamemode lib32-gamemode mpg123 lib32-mpg123 openal lib32-openal ocl-icd lib32-ocl-icd gstreamer lib32-gstreamer vkd3d lib32-vkd3d vulkan-icd-loader lib32-vulkan-icd-loader python-glfw lib32-vulkan-validation-layers vulkan-devel mesa lib32-mesa libva-mesa-driver mesa-vdpau ufw usbguard libpwquality kde-cli-tools ntp xdg-user-dirs geoclue rng-tools discord meld kcolorchooser kontrast dmg2img telegram-desktop gcompris-qt --noconfirm
#
