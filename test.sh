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
#Переменная сохранит ширину экрана.
w=0
#Переменная сохранит диагональ экрана.
d=0
#Переменная сохранит соотношение ширины и диагонали экрана.
px=0
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
#Массив, хранит шрифты.
massfont=(30144_PostIndex.ttf https://ttfonts.net/ru/download/31252.htm $(curl https://fonts.google.com/download/list?family=Stalinist+One \
                 https://fonts.google.com/download/list?family=Noto%20Emoji \
                 https://fonts.google.com/download/list?family=Noto%20Sans%20Symbols \
                 https://fonts.google.com/download/list?family=Noto%20Sans%20Symbols%202 \
                 https://fonts.google.com/download/list?family=Noto%20Sans%20Duployan \
                 https://fonts.google.com/download/list?family=Noto%20Music \
                 https://fonts.google.com/download/list?family=Noto%20Sans%20Math \
                 https://fonts.google.com/download/list?family=Noto%20Sans \
                 https://fonts.google.com/download/list?family=Noto%20Sans%20Arabic \
                 https://fonts.google.com/download/list?family=Noto%20Serif \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20TC \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Armenian \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Gurmukhi \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Gujarati \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Tamil \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Hebrew \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20JP \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20KR \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Khmer \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Georgian \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Kannada \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Thai \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Devanagari \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20Bengali \
                 https://fonts.google.com/download/list?family=Noto%20Serif%20SC \
                 | grep --color=never '.ttf"' | awk '{print $2}' | sed 's/[,"]//g' | sed 's/static\///'))
massallprog=( wayland \
xorg-server-xwayland \
libinput \
foot \
foot-terminfo \
swayidle \
cmatrix \
sway \
waybar \
wofi \
jq \
bemenu \
ly \
terminus-font \
arch-audit \
firefox \
firefox-i18n-ru \
firefox-spell-ru \
firefox-ublock-origin \
firefox-dark-reader \
links \
thunderbird \
thunderbird-i18n-ru \
xdg-desktop-portal-gtk \
xdg-desktop-portal-kde \
xdg-desktop-portal-wlr \
xdg-desktop-portal \
grim \
slurp \
swappy \
wl-clipboard \
qt5-wayland \
qt6-wayland \
network-manager-applet \
networkmanager-strongswan \
krdc \
blueman \
bluez \
bluez-utils \
bluez-qt \
git \
mc \
htop \
nano \
nano-syntax-highlighting \
dhcpcd \
imagemagick \
acpid \
clinfo \
avahi \
reflector \
go \
libnotify \
openssh \
dbus-broker \
kmsvnc \
polkit \
gnome-keyring \
lxqt-policykit \
gparted \
gpart \
exfatprogs \
archlinux-xdg-menu \
7zip \
dosfstools \
unzip \
smartmontools \
ifuse \
usbmuxd \
libplist \
libimobiledevice \
curlftpfs \
samba \
smbclient \
wsdd \
ffmpegthumbnailer \
nemo \
cinnamon-translations \
file-roller \
nemo-fileroller \
gvfs \
gvfs-mtp \
gvfs-afc \
gvfs-smb \
gvfs-dnssd \
gigolo \
kclock \
calindori \
papirus-icon-theme \
wlsunset \
grc \
swaync \
archlinux-wallpaper \
cosmic-wallpapers \
elementary-wallpapers \
awww \
conky \
freetype2 \
ttf-fantasque-sans-mono \
gnome-font-viewer \
fastfetch \
alsa-utils \
alsa-plugins \
lib32-alsa-plugins \
alsa-firmware \
alsa-card-profiles \
pipewire \
pipewire-alsa \
pipewire-pulse \
pipewire-jack \
wireplumber \
sof-firmware \
pavucontrol-qt \
sound-theme-freedesktop \
aspell \
nuspell \
xed \
kamoso \
aspell-en \
aspell-ru \
ethtool \
kolourpaint \
vlc \
vlc-plugin-ffmpeg \
libreoffice-still-ru \
hunspell \
hunspell-en_us \
hyphen \
hyphen-en \
libmythes \
mythes-en \
gimagereader-gtk \
tesseract-data-rus \
tesseract-data-eng \
kalgebra \
copyq \
kamera \
geeqie \
xreader \
audacious \
sane \
skanlite \
nss-mdns \
cups-pk-helper \
cups \
cups-pdf \
system-config-printer \
steam \
wine \
winetricks \
wine-mono \
wine-gecko \
gamemode \
lib32-gamemode \
lib32-libappindicator \
mpg123 \
lib32-mpg123 \
openal \
lib32-openal \
ocl-icd \
lib32-ocl-icd \
gstreamer \
lib32-gstreamer \
vkd3d \
lib32-vkd3d \
vulkan-icd-loader \
lib32-vulkan-icd-loader \
lib32-vulkan-validation-layers \
vulkan-utility-libraries \
vulkan-tools \
vulkan-extra-tools \
vulkan-extra-layers \
mesa \
lib32-mesa \
usbguard \
libpwquality \
xdg-user-dirs \
geoclue \
rng-tools \
cpu-x \
hunspell-ru-aot \
hyphen-ru \
ananicy-cpp \
kde-cdemu-manager \
usbguard-qt \
kmscon \
breeze \
breeze-gtk \
breeze-icons \
plasma-integration \
gsettings-desktop-schemas \
discord \
meld \
kcolorchooser \
kontrast \
telegram-desktop \
cups-xerox-b2xx)
massprog=()
massallaurprog=()
massaurprog=()
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
timedatectl set-timezone "$(curl -f https://ipapi.co/timezone)"
echo -e "\033[36mЧасовой пояс:"$(curl -f https://ipapi.co/timezone)"\033[0m"
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
echo -e "\033[36mРасчет размера шрифта и окон.\033[0m"
echo -e "\033[47m\033[30mВыберите диапазон разрешения монитора:\033[0m\033[32m"
PS3="$(echo -e ">")"
select menuscreen in "~480p." "~720p-1080p." "~4K."
do
    case "$menuscreen" in
        "~480p.")
            w=100
            xterm="500 350"
            fox=0.0
            break
            ;;
        "~720p-1080p.")
            w=200
            xterm="1000 500"
            fox=1.0
            break
            ;;
        "~4K.")
            w=400
            xterm="2000 1000"
            fox=1.5
            break
            ;;
        *) echo -e "\033[41m\033[30mЧто значит - "$REPLY"? До трёх посчитать не можешь и Arch Linux ставишь?\033[0m\033[32m";;
    esac
done
echo -e "\033[47m\033[30mДиагональ экрана в дюймах, только натуральное число:\033[0m\033[32m";read -p ">" d
while true
    do
        if [[ "$d" =~ ^[0-9]+$ ]];
            then
                break
            else
                echo -e "\033[41m\033[30mЧто значит - "$d"? Только НАТУРАЛЬНОЕ число\033[0m\033[32m"
                read d
        fi
    done
px=$(echo "3^($w/$d)" | bc)
while true
    do
        if [[ $(echo "$px>0" | bc) == 0 ]];
            then
                break
            else
                px=$(echo "$px/3" | bc)
                (( font++ ))
            fi
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
rootsize=$(echo "$rootsize/5*2" | bc)
varsize=$(echo "$rootsize/2" | bc)
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
+1G
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
        echo -e "\033[36mУдаление EFI записей сирот.\033[0m"
        massefi=($(efibootmgr | grep -v "\.EFI" | awk '{print $1}' | grep "*" | cut -c 5-8 | xargs))
for (( j=0, i=1; i<="${#massefi[*]}"; i++, j++ ))
            do
                efibootmgr -b "${massefi[$j]}" -B
            done
        echo -e "\033[36mUEFI boot.\033[0m"
fdisk /dev/"$sysdisk"<<EOF
g
n
1
2048
+1G
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
pacman -Sy usbguard --noconfirm
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
sed -i "s/UMASK$PARTITION_COLUMN.*/UMASK   027/" /mnt/etc/login.defs
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
        echo -e "title Arch Linux\nlinux /vmlinuz-linux-zen"$microcode"\ninitrd /initramfs-linux-zen.img\noptions root=/dev/"$sysdisk""$p3" rw resume=/dev/"$sysdisk""$p2"" > /mnt/boot/loader/entries/arch.conf
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
kernel.ctrl_alt_del=0
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
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.icmp_echo_ignore_all=0
net.ipv6.icmp.echo_ignore_all=0
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
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_tw_reuse=1
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50
net.ipv4.ip_forward=1
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1" > /mnt/etc/sysctl.d/99-sysctl.conf
#
#Установка видеодрайвера.
GPU_INFO=$(lspci | grep -iE 'vga|3d')
if echo "$GPU_INFO" | grep -iq "nvidia"; then
    if echo "$GPU_INFO" | grep -iE -q 'TU1|GA1|GV1|GP10|GM20|GM10|AD1|GB1'; then
        arch-chroot /mnt pacman -Sy nvidia-open-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia opencv-cuda nvtop cuda --noconfirm
        sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf
        echo "options nvidia_drm modeset=1 fbdev=1" > /mnt/etc/modprobe.d/nvidia.conf
    else
        sed -i 's/MODULES=()/MODULES=(nouveau)/' /mnt/etc/mkinitcpio.conf
    fi
elif echo "$GPU_INFO" | grep -iE -q 'vmware svga|virtualbox'; then
    arch-chroot /mnt pacman -Sy virtualbox-guest-utils --noconfirm
    sed -i 's/MODULES=()/MODULES=(vmwgfx vboxvideo vboxguest)/' /mnt/etc/mkinitcpio.conf
elif echo "$GPU_INFO" | grep -iq "AMD"; then
    arch-chroot /mnt pacman -Sy vulkan-radeon lib32-vulkan-radeon --noconfirm
    sed -i 's/MODULES=()/MODULES=(amdgpu)/' /mnt/etc/mkinitcpio.conf
elif echo "$GPU_INFO" | grep -iq "intel"; then
    arch-chroot /mnt pacman -Sy vulkan-intel intel-media-driver libva-intel-driver --noconfirm
    sed -i 's/MODULES=()/MODULES=(i915)/' /mnt/etc/mkinitcpio.conf
fi
#Установка компонентов и программ ОС.
echo -e "\033[36mУстановка компонентов и программ ОС.\033[0m"
for (( i=0; i<"${#massallprog[*]}"; i++ ))
            do
                if [ -n "$(pacman -Ssq "${massallprog[$i]}" | grep --color=never ^"${massallprog[$i]}" | head -n 1)" ];
                    then massprog+=( "$(pacman -Ssq "${massallprog[$i]}" | grep --color=never ^"${massallprog[$i]}" | head -n 1)" )
                    else massallaurprog+=( "${massallprog[$i]}" )
                fi
            done
arch-chroot /mnt pacman -Sy "${massprog[@]}" --noconfirm
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
                    then mount -o nodev,nosuid -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"${massparts[$j]}"
                    else mount -o nodev,nosuid --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"${massparts[$j]}"
                fi
masslabel+='
${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}~/Documents/Devices/'"${massparts[$j]}"'${hr 1}$color
(${fs_type /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'})${fs_bar '"$font"','"$(($font*6))"' /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} $alignr${color #f92b2b}${fs_used /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} / $color${fs_free /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'} / ${color #b2b2b2}${fs_size /home/'"$username"'/Documents/Devices/'"${massparts[$j]}"'}'
            else
                if [ "$(lsblk -fn /dev/"${massparts[$j]}" | awk '{print $2}')" = "vfat" ];
                    then mount -o nodev,nosuid -i -t vfat -oumask=0000,iocharset=utf8 "$@" --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                    else mount -o nodev,nosuid --mkdir /dev/"${massparts[$j]}" /mnt/home/"$username"/Documents/Devices/"$(lsblk -no LABEL /dev/"${massparts[$j]}")"
                fi
masslabel+='
${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}${execi 10 sudo smartctl -A /dev/'"${massparts[$j]}"' | grep -i temperature: | awk \047{print $2}\047}°C ${color #f92b2b}~/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'${hr 1}$color
(${fs_type /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'})${fs_bar '"$font"','"$(($font*6))"' /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}$alignr${fs_used /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #f92b2b}${fs_free /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'} / ${color #b2b2b2}${fs_size /home/'"$username"'/Documents/Devices/'"$(lsblk -no LABEL /dev/"${massparts[$j]}")"'}'
        fi
    done
#
#Копирование файла автоматического монтирования разделов.
echo -e "\033[36mКопирование файла автоматического монтирования разделов.\033[0m"
genfstab -L /mnt >> /mnt/etc/fstab
#
#Правка fstab для ntfs.
echo -e "\033[36mПравка fstab для ntfs.\033[0m"
sed -i "s/ntfs $PARTITION_COLUMN.*/ntfs3       iocharset=utf8,showexec,umask=000,dmask=0027,fmask=0137,uid=1000,gid=1000       0 0/" /mnt/etc/fstab
#
#Настройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).
echo -e "\033[36mНастройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).\033[0m"
ln -sf /mnt/usr/lib32/libstdc++.so.6 /usr/lib32/libstdc++.so.6
ln -sf /mnt/usr/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
ln -sf /mnt/usr/lib32/libstdc++.so /usr/lib32/libstdc++.so
ln -sf /mnt/usr/lib/libstdc++.so /usr/lib/libstdc++.so
usbguard generate-policy > /mnt/etc/usbguard/rules.conf
#
#Установка переменных окружения.
echo -e "\\033[36mУстановка переменных окружения.\\033[0m"
echo -e 'GTK_USE_PORTAL=1
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gtk3
GDK_BACKEND=wayland,x11
MOZ_ENABLE_WAYLAND=
XDG_MENU_PREFIX=arch-
SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/keyring/ssh"' >> /mnt/etc/environment
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
${color #b2b2b2}IP:$alignr${curl eth0.me}$color↑${upspeedf '"$netdev"'} \\
${upspeedgraph '"$netdev"' '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t} \\
$alignr↓${downspeedf '"$netdev"'} \\
${downspeedgraph '"$netdev"' '"$font"','"$(($font*6))"' b2b2b2 f92b2b -t}
#Блок "Системный диск".
${color #f92b2b}HDD/SSD${hr 3}$color
${color #b2b2b2}\\
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}\\
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C \\
${color #f92b2b}/root${hr 1}$color
(${fs_type /root})${fs_bar '"$font"','"$(($font*6))"' /root} \\
$alignr${color #f92b2b}${fs_used /root} / $color${fs_free /root} / ${color #b2b2b2}\\
${fs_size /root}
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}\\
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C \\
${color #f92b2b}/var${hr 1}$color
(${fs_type /var})${fs_bar '"$font"','"$(($font*6))"' /var} \\
$alignr${color #f92b2b}${fs_used /var} / $color${fs_free /var} / ${color #b2b2b2}\\
${fs_size /var}
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature_celsius | awk -F \047-\047 \047{print $NF}\047 | awk \047{print $1}\047}\\
${execi 10 sudo smartctl -A /dev/'"$sysdisk"' | grep -i temperature: | awk \047{print $2}\047}°C \\
${color #f92b2b}/home${hr 1}$color
(${fs_type /home})${fs_bar '"$font"','"$(($font*6))"' /home} \\
$alignr${color #f92b2b}${fs_used /home} / $color${fs_free /home} / ${color #b2b2b2}${fs_size /home}'"${masslabel[@]}"'
]]' | tee /mnt/home/"$username"/.config/conky/conky.conf /mnt/root/.config/conky/conky.conf
#
# Заставляем программы на Qt5 и Qt6 использовать темную тему
mkdir -p /mnt/{home/"$username",root}/.config/{swaync,foot,sway,waybar,wofi,copyq}
cp /mnt/usr/share/color-schemes/BreezeDark.colors /mnt/home/"$username"/.config/kdeglobals
cp /mnt/usr/share/color-schemes/BreezeDark.colors /mnt/root/.config/kdeglobals
echo -e "\n[Icons]\nTheme=Papirus-Dark" | tee -a /mnt/home/"$username"/.config/kdeglobals /mnt/root/.config/kdeglobals
#
#Создание конфига bash_profile (Настройка Xorg).
echo -e "\033[36mСоздание конфига bash_profile (Настройка Xorg).\033[0m"
echo '[[ -f ~/.profile ]] && . ~/.profile' | tee /mnt/home/"$username"/.bash_profile /mnt/root/.bash_profile
#
#Создание конфига xdg-desktop-portal (Настройка Xdg).
echo -e "\033[36mСоздание конфига xdg-desktop-portal (Настройка Xdg).\033[0m"
echo -e "[preferred]
default=wlr;gtk;
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.ScreenCast=wlr" > /mnt/etc/xdg/xdg-desktop-portal/portals.conf
#
#Создание конфига bashrc.
echo -e "\033[36mСоздание конфига bashrc.\033[0m"
echo '[[ $- != *i* ]] && return #Определяем интерактивность шелла.
# Алиасы для раскрашивания вывода
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ls="ls --color=auto"
alias df="grc df -h"
export GRC_ALIASES=true
# Подключение утилиты Generic Colouriser (grc)
[[ -s "/etc/profile.d/grc.sh" ]] && source /etc/profile.d/grc.sh
#Изменяем вид приглашения командной строки (Powerline стиль)
PS1="\[\e[48;2;249;43;43m\]\[\e[38;2;43;249;43m\] \$\[\e[48;2;249;249;43m\]\[\e[38;2;249;43;43m\]\[\e[48;2;249;249;43m\]\[\e[38;2;43;43;249m\]\A\[\e[48;2;43;43;249m\]\[\e[38;2;249;249;43m\] \u@\h\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;249m\]\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;43m\]\W\[\e[48;2;43;43;43m\]\[\e[0m\]\[\e[38;2;43;249;43m\] \[\e[0m\]"
# Настройки истории команд и цветопередачи
export HISTCONTROL="ignoreboth"
export COLORTERM=truecolor' | tee /mnt/home/"$username"/.bashrc /mnt/root/.bashrc
#
#Создание конфига profile.
echo -e "\033[36mСоздание конфига profile.\033[0m"
echo '[[ -f ~/.bashrc ]] && . ~/.bashrc #Указание на bashrc.
export QT_QPA_PLATFORM="wayland;xcb"
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORMTHEME=gtk3
export XCURSOR_THEME=breeze_cursors
export XCURSOR_SIZE=24' | tee /mnt/home/"$username"/.profile /mnt/root/.profile
#
#Редактирование конфига сервера уведомлений.
echo -e "\033[36mРедактирование конфига сервера уведомлений.\033[0m"
echo '{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "positionX": "right",
  "positionY": "top",
  "layer": "overlay",
  "control-center-margin-top": 10,
  "control-center-margin-right": 10,
  "notification-icon-size": 64,
  "notification-body-image-height": 100,
  "notification-body-image-width": 200,
  "timeout": 5,
  "timeout-low": 2,
  "timeout-critical": 0,
  "fit-to-screen": true,
  "sound": true,
  "sound-theme": "freedesktop"
}' | tee /mnt/home/"$username"/.config/swaync/config.json /mnt/root/.config/swaync/config.json
#
#Настройки терминала Foot.
echo -e "\033[36mНастройки терминала Foot.\033[0m"
echo 'font=Fantasque Sans Mono:size='$font'
term=foot
[environment]
TERMINAL_EMULATOR=foot
[scrollback]
lines=10000
indicator-format=none
[cursor]
blink=yes
style=block
[colors-dark]
background=2b2b2b
foreground=2bf92b
cursor=2b2b2b f92b2b' | tee /mnt/home/"$username"/.config/foot/foot.ini /mnt/root/.config/foot/foot.ini
#
#Создание директории и конфига sway (Тайловый оконный менеджер).
echo -e "\033[36mСоздание конфига sway (Тайловый оконный менеджер).\033[0m"
echo -e '########### Основные настройки ###########
#
# Включаем NumLock по умолчанию
input * xkb_numlock enabled
#
# Настройка клавиатуры внутри сессии Sway (ENG/RUS, Alt+Shift, Ctrl+Alt+Backspace)
input "type:keyboard" {
    xkb_layout us,ru
    xkb_options grp:alt_shift_toggle,terminate:ctrl_alt_bksp
}
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
# Следующее открытое окно разделит экран по горизонтали.
bindsym $mod+h split h
#
# Следующее открытое окно разделит экран по вертикали.
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
# Настройка кнопок мыши в комбинации с клавишей Win (Mod4)
# Чтобы случайно не ломать интерфейс программ, действия привязаны к удерживанию $mod
bindsym $mod+button5 kill                      # Win + Прокрутка вниз: закрыть окно
bindsym $mod+button4 fullscreen toggle         # Win + Прокрутка вверх: во весь экран
bindsym $mod+button3 floating toggle           # Win + Правый клик: сделать плавающим
bindsym $mod+button2 move scratchpad           # Win + Средний клик: отправить в черновик
#
# Определяем имена для рабочих областей по умолчанию.
set $ws1 "1: 🏠"
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
# Перечитать файл конфигурации (Обновление интерфейса на лету).
bindsym $mod+Shift+c reload
#
# Выход из Sway.
bindsym $mod+Shift+e exec swaynag -t warning \\
  -m \047Вы действительно хотите выйти из Sway? Это завершит вашу графическую сессию.\047 \\
  -B \047Да, выйти из Sway' 'pw-play /usr/share/sounds/freedesktop/stereo/service-logout.oga && swaymsg exit\047
#
# Войти в режим изменения размеров окон.
bindsym $mod+r mode "resize"
#
# Изменить размер окна.
mode "resize" {
        bindsym Left resize shrink width 10 px or 5 ppt
        bindsym Down resize grow height 10 px or 5 ppt
        bindsym Up resize shrink height 10 px or 5 ppt
        bindsym Right resize grow width 10 px or 5 ppt
        
        # Выйти из режима изменения размеров окон.
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}
#
########### Внешний вид ###########
# 1. Скругление углов (SwayFX)
#TechnicalSymbolV corner_radius '$font'
#TechnicalSymbolV smart_corner_radius on
#TechnicalSymbolV for_window [app_id="waybar"] corner_radius 0
#
# Исключения для скругления
#TechnicalSymbolV smart_corner_radius on
#TechnicalSymbolV for_window [app_id="waybar"] corner_radius 0
#
# 2. Затемнение неактивных окон (SwayFX)
#TechnicalSymbolV for_window [all] dim 0.35
#
# 3. Эффекты теней (SwayFX)
#TechnicalSymbolV shadows on
#TechnicalSymbolV shadows_on_csd off
#TechnicalSymbolV shadow_blur_radius 15
#TechnicalSymbolV shadow_color #000000A0
#
# 4. Прозрачность окон
#TechnicalSymbolV for_window [app_id="foot"] opacity 0.80
#TechnicalSymbolV for_window [app_id="wofi"] opacity 0.90
#TechnicalSymbolV for_window [app_id="bemenu"] opacity 0.90
#TechnicalSymbolV for_window [app_id="vlc"] opacity 1.0
#
# Принудительная 100% непрозрачность для медиа и полноэкранного режима
#TechnicalSymbolV for_window [app_id="vlc"] opacity 1.0
#TechnicalSymbolV for_window [fullscreen] opacity 1.0
#
#TechnicalSymbolV # 5. Размытие заднего плана (SwayFX)
#TechnicalSymbolV blur on
#TechnicalSymbolV blur_xray off
#TechnicalSymbolV blur_passes 5
#TechnicalSymbolV blur_radius 5
#TechnicalSymbolV for_window [app_id="vlc"] blur off
#
# Шрифт для заголовков окон
font pango:Fantasque Sans Mono Bold '$font'
#
# Просветы между окнами
gaps inner '$font'
#
# Толщина границы окна
default_border normal 1
#
# Устанавливаем цвета рамок окон (Граница, ФонТекста, Текст, Индикатор, ДочерняяГраница)
client.focused          #2b2b2b #2b2b2b #2bf92b #2b2b2b #2b2b2b
client.unfocused        #000000 #000000 #b2b2b2 #000000 #000000
client.focused_inactive #000000 #000000 #b2b2b2 #000000 #000000
client.urgent           #000000 #000000 #b2b2b2 #000000 #000000
client.placeholder      #000000 #000000 #b2b2b2 #000000 #000000
#
# ПРАВИЛА ПОВЕДЕНИЯ ОКНОН
#
# Внешний вид терминала Foot
# Если вы запускаете foot в режиме плавающего окна:
for_window [app_id="foot" title="floating_terminal"] floating enable
for_window [app_id="foot" title="floating_terminal"] sticky enable
for_window [app_id="foot" title="floating_terminal"] resize set '$xterm'
#
# Включить плавающий режим для музыкального плеера Audacious
for_window [app_id="audacious"] floating enable
#
# Включить плавающий режим для календаря и часов KDE
for_window [app_id="org.kde.calindori"] floating enable
for_window [app_id="org.kde.kclock"] floating enable
#
########### НАТИВНАЯ НАСТРОЙКА ТАЧПАДА ###########
input "type:touchpad" {
    tap enabled                  # Включение клика по касанию (Option "Tapping" "on")
    natural_scroll enabled       # Включение естественной прокрутки (инверсия скролла двумя пальцами)
    dwt enabled                  # Disable While Typing (отключение тачпада во время печати текста для защиты от ладоней)
    scroll_factor 0.5            # Скорость прокрутки (можно настроить под себя)
}
#
########### МУЛЬТИМЕДИЙНЫЕ И СИСТЕМНЫЕ КЛАВИШИ ###########
# Регулировка громкости (wpctl — нативный инструмент Wireplumber/PipeWire)
# Canberra выдает чистый системный звук изменения уровня громкости
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && canberra-gtk-play -i audio-volume-change
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && canberra-gtk-play -i audio-volume-change
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && canberra-gtk-play -i audio-volume-change
# Отключить / Включить микрофон
bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
# Быстрый запуск калькулятора KAlgebra по специальной клавише
bindsym XF86Calculator exec kalgebra
# Быстрый запуск почтового клиента Thunderbird
bindsym XF86Mail exec thunderbird
#
# Скриншот (Создание снимка через grim/slurp + звук затвора камеры)
bindsym Print exec grim -g "$(slurp)" - | swappy -f - && canberra-gtk-play -i screen-capture
#
########### Автозапуск программ ###########
#
# Инициализация GNOME Keyring
exec gnome-keyring-daemon --start --components=pkcs11,secrets,ssh
#
# Графический окошко с запросом паролей Polkit
exec /usr/bin/lxqt-policykit-agent
#
# Инициализация демона обоев и запуск циклической смены картинок раз в 5 минут
exec awww-daemon --format xrgb
exec bash -c \047while true; do awww img $(find /usr/share/backgrounds/ -type f | shuf -n 1) --transition-type random; sleep 300; done\047 &
#
# Автозапуск сервера уведомлений SwayNC
exec swaync
#
# Автозапуск статус-бара Waybar
exec waybar
#
# Блокировка экрана, заставка cmatrix и гибернация
exec swayidle -w \\
     timeout 300 \047foot --fullscreen cmatrix -sba\047 \\
     resume \047killall cmatrix\047 \\
     timeout 1800 \047swaylock -f -c 000000\047 \\
     timeout 3000 \047systemctl hibernate\047 \\
     before-sleep \047swaylock -f -c 000000\047
#
# Воспроизведение звука входа
exec pw-play /usr/share/sounds/freedesktop/stereo/service-login.oga
#
# Приветственное уведомление при входе в систему (Текст адаптирован под Sway)
exec notify-send -t 10000 -i user-red-home "☭ Доброго времени суток ☭" "В меню 🛈 -- Шпаргалка по SwayWM."
#
# Автоматический сканер уязвимостей Arch Linux при старте
exec bash -c \047notify-send -w "✊ Сканер уязвимостей ✊" "$(arch-audit)"\047
#
# Автозапуск системного монитора Conky (В режиме Wayland)
exec conky
#
# Сеть, Bluetooth и Системный трей
exec nm-applet --indicator
exec blueman-applet
exec /usr/lib/geoclue-2.0/demos/agent
#
# Менеджер буфера обмена CopyQ (Нативная работа в Wayland)
exec copyq
#
# Демон безопасности USBGuard (Запуск БЕЗ sudo, права предоставит Polkit)
exec usbguard-qt
#
# Мультимедиа, Календари и Мессенджеры в трей
exec audacious -H
exec kclockd
exec calindac
exec wlsunset -T 4500 -t 3500 -g 1
exec telegram-desktop -startintray
#
# Автозапуск fastfetch и обновления.
#TechnicalSymbolexec bash -c \047sleep 10; \\
#TechnicalSymbol while [[ 1 -gt "$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)" ]]; \\
#TechnicalSymbol do \\
#TechnicalSymbol sleep 5; \\
#TechnicalSymbol done; \\
#TechnicalSymbol sleep 5; \\
#TechnicalSymbol pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-2)}\047\\\047\047)"; \\
#TechnicalSymbol fastfetch > /dev/pts/$pts; \\
#TechnicalSymbol pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)"; \\
#TechnicalSymbol sudo rm /var/lib/pacman/db.lck > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Suy --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol yay -Suy --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Sc --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol yay -Sc --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Rsn $(pacman -Qdtq) --noconfirm > /dev/pts/$pts\047
#
########### Горячие клавиши запуска программ ###########
#
# Восстановление рабочего стола №1.
bindsym $mod+mod1+1 workspace number $ws1; exec foot; exec nemo
#
# Автоматический запуск при старте системы на 1-м рабочем столе.
exec swaymsg "workspace number $ws1; exec foot; exec nemo"
#
# Используйте mod+enter, чтобы запустить нативный терминал Foot.
bindsym $mod+Return exec foot
#
# Запуск меню программ Bemenu.
bindsym $mod+d exec bemenu-run --backend wayland -f "Fantasque Sans Mono Bold '"$(($font/2+$font))"'" -p "Поиск программы:" --nb "#2b2b2b" --sf "#2b2bf9" --nf "#2bf92b" --sb "#f92b2b"
#
# Используйте mod+f1, чтобы запустить браузер Firefox.
bindsym $mod+F1 exec firefox
#
# Сделать текущее окно черновиком/блокнотом.
bindsym $mod+Shift+minus move scratchpad
#
# Показать первое окно черновика/блокнота.
bindsym $mod+minus scratchpad show
#
# Снимок экрана.
bindsym $mod+Print exec grim - | swappy -f - && canberra-gtk-play -i screen-capture
#
########### Распределение окон по рабочим столам ###########
#
# Firefox будет автоматически запускаться на 2 рабочем столе (Замена class на app_id)
assign [app_id="firefox"] workspace number $ws2
#
# Steam будет запускаться на 3 рабочем столе (Фильтр адаптирован под XWayland-окна Steam)
assign [class="Steam"] workspace number $ws3
assign [app_id="vlc"] workspace number $ws4
#
exec firefox; #TechnicalString
exec bash -c \047sleep 10; ~/archinstall.sh > /dev/pts/1\047 #TechnicalString' | tee /mnt/home/"$username"/.config/sway/config /mnt/root/.config/sway/config
#
#Создание конфига Polybar (Панель рабочего стола).
echo -e "\033[36mСоздание конфига Polybar (Панель рабочего стола).\033[0m"
echo -e '[
    // ==========================================
    //   ВЕРХНЯЯ ПАНЕЛЬ (UPBAR)
    // ==========================================
    {
        "layer": "top",
        "position": "top",
        "height": '$((font*3))',
        "spacing": 4,
        "modules-left": [
            "custom/jgmenu", "custom/inetbrowser", "custom/filebrowser", "custom/libreoffice",
            "custom/xed", "custom/calculator", "custom/kolourpaint", "custom/kamoso", "custom/skanlite"
        ],
        "modules-center": [ "window" ],
        "modules-right": [ "clock#time", "clock#date", "pulseaudio", "custom/printscreen", "custom/help", "custom/poweroff" ],
        "custom/jgmenu": {
        "format": " Arch Linux ☭ ",
        "on-click": "wofi --config ~/.config/wofi/config", // Открытие основного меню программ слева
        "tooltip": false
        },
        "custom/inetbrowser": { "format": " 🌐 ", "on-click": "xdg-open \047about:blank\047", "tooltip": false },
        "custom/filebrowser": { "format": " 🗂 ", "on-click": "nemo", "tooltip": false },
        "custom/libreoffice": { "format": " 🗋 ", "on-click": "libreoffice", "tooltip": false },
        "custom/xed": { "format": " 📃 ", "on-click": "xed", "tooltip": false },
        "custom/calculator": { "format": " 🖩 ", "on-click": "kalgebra", "tooltip": false },
        "custom/kolourpaint": { "format": " 🎨 ", "on-click": "kolourpaint", "tooltip": false },
        "custom/kamoso": { "format": " 📸 ", "on-click": "kamoso", "tooltip": false },
        "custom/skanlite": { "format": " 🖨️ ", "on-click": "skanlite", "tooltip": false },
        "window": { "format": "☭ {app_id} ➤ {title} ☭", "max-length": '$((font*4))' },
        "clock#time": { "interval": 1, "format": "{:%H:%M:%S}", "on-click": "kclock", "tooltip": false },
        "clock#date": { "interval": 1, "format": "{:%A, %d %B %Y}", "locale": "ru_RU.UTF-8", "on-click": "calindori", "tooltip": false },
        "pulseaudio": { "scroll-step": 5, "format": " ☭ {icon}{volume}% ☭ ", "format-muted": " ☭ 🔇00% ☭ ", "format-icons": { "default": ["🔈 ", "🔉 ", "🔊 "] }, "on-click-right": "pavucontrol-qt" },
        "custom/printscreen": { "format": "⎙ ", "on-click": "grim -g \"$(slurp)\" - | swappy -f - && canberra-gtk-play -i screen-capture", "tooltip": false },
        "custom/help": {
        "format": " 🛈 ",
        "on-click": "bash ~/.config/wofi/menu_help.sh", // Вызов меню справки
        "tooltip-format": "Помощь"
        },
        "custom/poweroff": {
        "format": " ⏻ ",
        "on-click": "bash ~/.config/wofi/menu_power.sh", // Вызов меню питания справа
        "tooltip-format": "Выключение"
        }
    },

    // ==========================================
    //   НИЖНЯЯ ПАНЕЛЬ (DOWNBAR)
    // ==========================================
    {
        "layer": "top",
        "position": "bottom",
        "height": '$((font*3))',
        "spacing": 4,
        // Модули нижней панели
        "modules-left": [
            "sway/workspaces"
        ],
        "modules-right": [
            "cpu",
            "memory",
            "custom/netline",
            "sway/language",
            "keyboard-state",
            "tray",
            "battery"
        ],
        // Настройка рабочих столов Sway
        "sway/workspaces": {
            "disable-scroll": false,
            "all-outputs": true,
            "format": "{name}",
            "persistent-workspaces": {
                "1": [], "2": [], "3": []
            }
        },
        // Мониторинг процессора
        "cpu": {
            "interval": 0.5,
            "format": "{usage}% CPU",
            "states": {
                "warning": 95
            }
        },
        // Мониторинг памяти
        "memory": {
            "interval": 3,
            "format": "💾: {used:0.1f}Gb/{avail:0.1f}Gb",
            "states": {
                "warning": 95
            }
        },
        // Сетевой скрипт netline
        "custom/netline": {
            "exec": "netline=\"| \"; netmas=\"$(nmcli -f GENERAL.DEVICE device show | awk \047!/lo/ && !/^$/ {print $2}\047)\"; for word in $netmas; do netline+=\"$word: $(nmcli -f IP4.ADDRESS device show \"$word\" | awk \047{print $2}\047)\\" | \"; done; echo \"$netline\"",
            "interval": 1,
            "tooltip": false
        },
        // Отображение текущего языка
        "sway/language": {
            "format": " {short} ",
            "tooltip": false
        },
        // Индикаторы блокировок
        "keyboard-state": {
            "numlock": true,
            "capslock": true,
            "scrolllock": true,
            "format": {
                "numlock": "{name}",
                "capslock": "{name}",
                "scrolllock": "{name}"
            },
            "format-icons": {
                "locked": "X", // Будет подсвечено большой буквой через CSS
                "unlocked": "x"
            }
        },
        // Системный трей Wayland (Status Notifier Item)
        "tray": {
            "icon-size": '$((font*2))',
            "spacing": 10
        },
        // Монитор батареи (С вашими иконками)
        "battery": {
            "states": {
                "good": 99,
                "warning": 15,
                "critical": 5
            },
            "format": "{icon} {capacity}%",
            "format-charging": "  {capacity}%",
            "format-plugged": "  {capacity}%",
            "format-icons": ["", "", "", "", ""]
        }
    }
]' | tee /mnt/home/"$username"/.config/waybar/config.jsonc /mnt/root/.config/waybar/config.jsonc
#
#ГЕНЕРАЦИЯ СТИЛЕЙ ОФОРМЛЕНИЯ И ПОДВЕТОК (CSS)
echo -e '/* Базовые стили для обеих панелей */
* {
    border: none;
    border-radius: 0;
    font-family: "Fantasque Sans Mono", "Noto Sans Symbols", "Noto Emoji";
    font-size: '${font}'px;
    min-height: 0;
}
window#waybar {
    background-color: #2b2b2b;
    color: #b2b2b2;
}
#window { color: #ffa500; font-weight: bold; }
#custom-jgmenu { color: #f92b2b; font-weight: bold; }
#custom-jgmenu, #custom-inetbrowser, #custom-filebrowser, #custom-libreoffice, 
#custom-xed, #custom-calculator, #custom-kolourpaint, #custom-kamoso, #custom-skanlite,
#custom-printscreen, #custom-help, #custom-poweroff, #clock, #pulseaudio {
    padding: 0 5px;
}
#custom-jgmenu:hover, #custom-inetbrowser:hover, #custom-filebrowser:hover, #custom-libreoffice:hover,
#custom-xed:hover, #custom-calculator:hover, #custom-kolourpaint:hover, #custom-kamoso:hover, #custom-skanlite:hover,
#custom-printscreen:hover, #custom-help:hover, #custom-poweroff:hover, #clock:hover {
    background-color: #283544;
    color: #2bf92b;
}
/* --- МОДУЛИ НИЖНЕГО БАРА --- */
#cpu, #memory, #custom-netline, #language, #keyboard-state, #battery {
    padding: 0 5px;
    border-left: 2px solid #f92b2b;
}
/* Стилизация рабочих столов */
#workspaces button {
    padding: 0 10px;
    background-color: transparent;
    color: #b2b2b2;
    border-bottom: 3px solid transparent;
}
#workspaces button.focused {
    background-color: #283544;
    color: #2bf92b;
    border-bottom: 3px solid #f92b2b;
}
#workspaces button.urgent {
    background-color: #f92b2b;
    color: #2b2b2b;
}
/* Подсветка критической нагрузки CPU и памяти */
#cpu.warning, #memory.warning {
    background-color: #f92b2b;
    color: #000000;
}
/* Стилизация переключателя языков */
#language {
    background-color: #283544;
    color: #ffffff;
    text-transform: uppercase;
}

/* Стилизация блока Caps/Num/ScrollLock */
#keyboard-state {
    background-color: #283544;
    color: #ffffff;
}
#keyboard-state label.locked {
    color: #ffffff; /* Заглавная буква если включен */
}
#keyboard-state label.unlocked {
    color: #666666; /* Маленькая серая буква если выключен */
}
/* Системный трей */
#tray {
    background-color: #2b2b2b;
}' | tee /mnt/home/"$username"/.config/waybar/style.css /mnt/root/.config/waybar/style.css
#
#Создание конфигурации для wlsunset.
echo -e "\033[36mНастройка GeoClue для нативного ночного режима wlsunset.\033[0m"
# Разрешаем демону wlsunset получать координаты от системы для автоматического расчета заката и рассвета
echo '[wlsunset]
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
#Создание подсказки.
echo -e "\033[36mСоздание подсказки.\033[0m"
echo '#
Win+Enter -- Запустить терминал (Foot).
Win+D -- Запуск Bemenu (программа запуска).
Win+F1 -- Запустить Firefox.
Win+Shift+Q -- Закрыть окно в фокусе.
Print Screen -- Снимок выделенной области экрана (Ножницы).
Win+Print Screen -- Снимок всего экрана.
#
🌐 -- Запустить Firefox.
🗂 -- Запустить Nemo.
🗋 -- Запустить LibreOffice.
📃 -- Запустить текстовый редактор Xed.
🖩 -- Запустить калькулятор KAlgebra.
🎨 -- Запустить kolourpaint.
📸 -- Запустить kamoso.
🖨️ -- Запустить Skanlite.
⎙ -- Снимок экрана/Ножницы.
🛈 -- Справка и шпаргалка.
⏻ -- Управление питанием ПК.
#
Win + ScrollUp на окне -- Развернуть окно во весь экран.
Win + ScrollDown на окне -- Закрывает окно.
Win + ПКМ на окне -- Переключение плавающего режима (Вкл/Выкл).
Win + СКМ на окне -- Сворачивает окно в черновик (Скретчпад).
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
Win+S -- Собрать окна в вертикальный стек.
Win+W -- Сделать из окон вкладки (как в браузере).
Win+E -- Переключить направление разделения окон.
#
Win+1..0 -- Переключение между рабочими столами.
Win+Shift+1..0 -- Переместить сфокусированное окно на заданный рабочий стол.
#
Win+Shift+C -- Перечитать конфигурационный файл Sway (Перезагрузка интерфейса).
Win+Shift+E -- Выход из графической сессии Sway (Безопасное завершение).
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
Win+Alt+1 -- Быстрый запуск терминала Foot и Nemo на рабочем столе №1.' > /mnt/help.txt
#
#Создание директории и конфига gtk (Внешний вид gtk программ).
echo -e "\033[36mСоздание конфига gtk (Внешний вид gtk программ).\033[0m"
mkdir -p /mnt/etc/{gtk-3.0,gtk-4.0}
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=breeze_cursors
gtk-font-name=Fantasque Sans Mono '"$font"'
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Breeze-Dark
gtk-decoration-layout=menu:
gtk-overlay-scrolling=false' | tee /mnt/etc/gtk-3.0/settings.ini /mnt/etc/gtk-4.0/settings.ini
echo 'gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name="Breeze"
gtk-font-name="Fantasque Sans Mono '"$font"'"
gtk-icon-theme-name="Papirus-Dark"
gtk-theme-name="Breeze-Dark"
gtk-decoration-layout=menu:' > /mnt/usr/share/gtk-2.0/gtkrc
#
echo -e "\033[36mСоздание конфига audacious.\033[0m"
mkdir -p /mnt/home/"$username"/.config/audacious /mnt/root/.config/audacious
echo '[statusicon]
close_to_tray=TRUE
reverse_scroll=TRUE' | tee -a /mnt/home/"$username"/.config/audacious/config /mnt/root/.config/audacious/config
#
echo -e "\033[36mСоздание конфига wireplumber.\033[0m"
mkdir -p /mnt/home/"$username"/.config/wireplumber/wireplumber.conf.d/
echo 'wireplumber.settings = {
  # Включаем глобальное автоматическое переключение на любое новое подключенное устройство
  node.features.audio.auto-switch = true
}
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        api.alsa.headphone-jack-detection = true
        api.alsa.mic-jack-detection = true
      }
    }
  }
]
monitor.bluez.rules = [
  {
    matches = [
      {
        # Применяется ко всем Bluetooth аудио-устройствам
        device.name = "~bluez_card.*"
      }
    ]
    actions = {
      update-props = {
        # Выставляем беспроводным наушникам наивысший приоритет при подключении
        node.shared-placement = true
        bluez5.auto-connect = [ a2dp_sink hfp_hf hsp_hs ]
      }
    }
  }
]' | tee -a /mnt/home/"$username"/.config/wireplumber/wireplumber.conf.d/95-hotplug-switch.conf /mnt/root/.config/wireplumber/wireplumber.conf.d/95-hotplug-switch.conf
#
echo -e "\033[36mНастройка звука.\033[0m"
mkdir -p /mnt/etc/pipewire/pipewire.conf.d/
# Прописываем наивысшее качество ресемплинга (10) и алгоритм
echo -e 'context.properties = {\n    spa.bluez5.codecs = [ ldac aptx_hd aptx sbc_xq sbc ]\n}' > /mnt/etc/pipewire/pipewire.conf.d/99-custom-audio.conf
# Для изменения именно качества ресемпла создается файл client.conf:
mkdir -p /mnt/etc/pipewire/client.conf.d/
echo -e 'filter.properties = {\n    resample.quality = 10\n}' > /mnt/etc/pipewire/client.conf.d/99-resample.conf
#
#Создание директории и конфига Wofi.
echo -e "\033[36mСоздание конфига Wofi.\033[0m"
echo '# Настройки поведения и внешнего вида Wofi
show=drun
width=400
height=500
location=top_left
xoffset=10
yoffset=40
layer=overlay
allow_images=true
image_size=32
term=foot
insensitive=true
prompt=Поиск программы:' | tee /mnt/home/"$username"/.config/wofi/config /mnt/root/.config/wofi/config
echo '#!/bin/bash
CHOSEN=$(echo -e "🛈  Подсказка по горячим клавишам\n📊  Переключить системный монитор Conky" | wofi --dmenu -p "Справка и Мониторинг:" --width=350 --height=150 --location=top_right --xoffset=-100 --yoffset=40)
case "$CHOSEN" in
    *"Подсказка"*)
        foot -t "floating_terminal" xed /help.txt &
        ;;
    *"Conky"*)
        # Переключение Conky (если запущен - убиваем, если нет - запускаем)
        if pidof conky >/dev/null; then
            killall conky
        else
            conky &
        fi
        ;;
esac' | tee /mnt/home/"$username"/.config/wofi/menu_help.sh /mnt/root/.config/wofi/menu_help.sh
echo '#!/bin/bash
CHOSEN=$(echo -e "🚪  Выйти из графической сессии Sway\n🔄  Перезагрузка компьютера\n⏻  Завершение работы (Выключение)" | wofi --dmenu -p "Управление питанием:" --width=350 --height=180 --location=top_right --xoffset=-10 --yoffset=40)
case "$CHOSEN" in
    *"Выйти"*)
        swaynag -t warning -m \047Вы действительно хотите выйти из Sway?\047 -B \047Да, выйти\047 \047pw-play /usr/share/sounds/freedesktop/stereo/service-logout.oga && swaymsg exit\047
        ;;
    *"Перезагрузка"*)
        systemctl reboot
        ;;
    *"Завершение"*)
        systemctl poweroff
        ;;
esac' | tee /mnt/home/"$username"/.config/wofi/menu_power.sh /mnt/root/.config/wofi/menu_power.sh
#
#Создание пользовательских директорий.
echo -e "\033[36mСоздание пользовательских директорий.\033[0m"
mkdir -p /mnt/home/"$username"/Documents/{Downloads,Public,Desktop,Music,Pictures,Templates,Videos} /mnt/root/Documents/{Downloads,Public,Desktop,Music,Pictures,Templates,Videos}
#
#Создание конфига samba (Стандартный набор программ взаимодействия Windows для Linux и Unix).
mkdir -p /mnt/home/"$username"/Documents/Public/
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
path = /home/'"$username"'/Documents/Public/
valid users = @wheel
guest ok = no
browsable = yes
writable = yes' > /mnt/etc/samba/smb.conf
#
#Создание конфига gigolo (браузер общих ресурсов Samba (SMB/CIFS)).
echo -e "\033[36mСоздание конфига gigolo (браузер общих ресурсов Samba (SMB/CIFS)).\033[0m"
mkdir -p /mnt/home/"$username"/.config/gigolo/
echo '[general]
file_manager=gio open
terminal=foot
autoconnect_interval=60
[ui]
save_geometry=true
show_in_systray=true
start_in_systray=true
show_toolbar=true
show_panel=true
show_autoconnect_errors=true' >> /mnt/home/"$username"/.config/gigolo/config
#
#Создание конфига copyq.
echo -e "\033[36mСоздание конфига copyq.\033[0m"
echo -e '[General]
plugin_priority=itemimage, itemtext, itemencrypted, itemtags, wayland
[Options]
check_clipboard=true
check_selection=false
copy_clipboard=true
copy_selection=false
hide_main_window=true' | tee /mnt/home/"$username"/.config/copyq/copyq.conf
#
#Редактирование конфига nanorc.
echo -e "\033[36mРедактирование конфига nanorc.\033[0m"
echo 'include "/usr/share/nano-syntax-highlighting/*.nanorc"' >> /mnt/etc/nanorc
sed -i 's/# set autoindent/set autoindent/' /mnt/etc/nanorc
sed -i 's/# set minibar/set minibar/' /mnt/etc/nanorc
sed -i 's/# set positionlog/set positionlog/' /mnt/etc/nanorc
sed -i 's/# set softwrap/set softwrap/' /mnt/etc/nanorc
sed -i 's/# set tabsize 8/set tabsize 4/' /mnt/etc/nanorc
sed -i 's/# set tabstospaces/set tabstospaces/' /mnt/etc/nanorc
sed -i 's/# set titlecolor/set titlecolor/' /mnt/etc/nanorc
#
#Установка шрифтов.
echo -e "\033[36mУстановка шрифтов.\033[0m"
for (( i=0; i<"${#massfont[*]}"; i=i+2 ))
    do
        curl --create-dirs -o /mnt/usr/share/fonts/google/"${massfont[$i]}" "${massfont[($i+1)]}"
    done
chmod o+rx /mnt/usr/share/fonts/google
mkfontdir /mnt/usr/share/fonts/google
mkfontdir /mnt/usr/share/fonts/TTF
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
#Создание конфигурации межсетевого экрана Nftables.
echo -e "\033[36mСоздание конфигурации nftables и настройка сети...\033[0m"
echo '#!/usr/bin/nft -f
table inet filter {
    set ssh_limit {
        type ipv4_addr
        flags dynamic, timeout
        timeout 1m
    }
    chain input {
        type filter hook input priority filter; policy drop;
        # Разрешаем уже установленные и связанные соединения (Критично для работы интернета)
        ct state established,related accept
        # Разрешаем локальный петлевой интерфейс (localhost)
        iif "lo" accept
        # Разрешаем весь трафик из вашей локальной сети
        ip saddr 192.168.0.0/24 accept
        # Ограничение и защита SSH (порт 22)
        tcp dport 22 ct state new update @ssh_limit { ip saddr limit rate over 4/minute } drop
        tcp dport 22 ct state new accept
        # Открываем порты для мультимедиа, сети и VNC
        tcp dport 5900 accept
        udp dport 5353 accept
        # Открываем порты для торрент-клиента Deluge
        tcp dport 58846 accept                        # Порт управления демоном Deluge
        tcp dport 6881 accept                         # Торрент-трафик TCP
        udp dport 6881 accept                         # Торрент-трафик UDP
    }
    chain forward {
        type filter hook forward priority filter; policy drop;
        # Разрешаем пересылку трафика, если входящий или выходящий интерфейс — wg0
        iifname "wg0" accept
        oifname "wg0" accept
        # Разрешаем пересылку уже существующих соединений
        ct state established,related accept
    }

    chain output {
        type filter hook output priority filter; policy accept; # Исходящий трафик разрешен всегда
    }
}' > /mnt/etc/nftables.conf
#
#Настройка удаленного рабочего стола.
echo -e "\033[36mНастройка удаленного рабочего стола.\033[0m"
echo '[Unit]
Description=KMS/DRM Framebuffer VNC Server
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service
[Service]
Type=simple
ExecStart=/usr/bin/kmsvnc --port 5900
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target' > /mnt/etc/systemd/system/kmsvnc.service
#
#Настройка ly-dm.
echo -e "\033[36mНастройка ly-dm.\033[0m"
sed -i 's/animation = none/animation = matrix/' /mnt/etc/ly/config.ini
sed -i 's/bigclock = none/bigclock = en/' /mnt/etc/ly/config.ini
sed -i 's/bigclock_seconds = false/bigclock_seconds = true/' /mnt/etc/ly/config.ini
sed -i 's/lang = en/lang = ru/' /mnt/etc/ly/config.ini
sed -i 's/fg = 0x00FFFFFF/fg = 0x0000FF00/' /mnt/etc/ly/config.ini
sed -i 's/border_fg = 0x00FFFFFF/border_fg = 0x0000FF00/' /mnt/etc/ly/config.ini
#
#Установка помощника yay для работы с AUR (Репозиторий пользователей).
echo -e "\033[36mУстановка помощника yay для работы с AUR (Репозиторий пользователей).\033[0m"
arch-chroot /mnt/ sudo -u "$username" bash -c 'cd /home/'"$username"'/
git clone https://aur.archlinux.org/yay.git
cd /home/'"$username"'/yay
BUILDDIR=/tmp/makepkg makepkg -i --noconfirm'
rm -Rf /mnt/home/"$username"/yay
#
#Установка программ из AUR (Репозиторий пользователей).
echo -e "\033[36mУстановка программ из AUR (Репозиторий пользователей).\033[0m"
for (( i=0; i<"${#massallaurprog[*]}"; i++ ))
            do
                if [ -n "$(arch-chroot /mnt sudo -u "$username" yay -Ssq "${massallaurprog[$i]}" | grep --color=never ^"${massallaurprog[$i]}" | tail -n 1)" ];
                    then massaurprog+=( "$(arch-chroot /mnt sudo -u "$username" yay -Ssq "${massallaurprog[$i]}" | grep --color=never ^"${massallaurprog[$i]}" | tail -n 1)" )
                fi
            done
arch-chroot /mnt sudo -u "$username" yay -S "${massaurprog[@]}" --noconfirm --ask 4
#
#Автозапуск служб.
echo -e "\033[36mАвтозапуск служб.\033[0m"
arch-chroot /mnt ln -sf /usr/lib/systemd/system/kmsconvt@.service /etc/systemd/system/autovt@.service
arch-chroot /mnt systemctl disable dbus
arch-chroot /mnt systemctl enable acpid bluetooth fancontrol NetworkManager reflector.timer \
ly@tty2 avahi-daemon ananicy-cpp dbus-broker rngd smartd smb \
wsdd saned.socket cups.socket kmsvnc auditd usbguard nftables
arch-chroot /mnt timedatectl set-ntp true
#
#Создание скрипта, который после перезагрузки продолжит установку.
echo -e "\033[36mСоздание скрипта, который после перезагрузки продолжит установку.\033[0m"
echo -e '#!/bin/bash
sleep 10
nmcli device wifi connect "'"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f" | sed s/.psk//)"'" password "'"$(grep Passphrase= /var/lib/iwd/"$(find /var/lib/iwd -type f -name "*.psk" -printf "%f")" | sed s/Passphrase=//)"'"
echo -e "\\033[36mЗавершение установки.\\033[0m"
#
#Счетчик.
while [[ -z "$(xwininfo -root -tree | grep -i firefox | grep -i mozilla)" ]]; do
    echo -e "\\033[31mПродолжение установки! \\033[0m"
    sleep 5
done
sleep 10
#
#Обнаружение кулеров.
echo -e "\\033[36mОбнаружение кулеров.\\033[0m"
sudo sensors-detect --auto
#
#Настройка браузера.
echo -e "\\033[36mНастройка браузера.\\033[0m"
ls ~/.mozilla/firefox/*.default-release
echo -e \047user_pref("layout.css.devPixelsPerPx", "'"$fox"'");
user_pref("accessibility.typeaheadfind", true);
user_pref("intl.regional_prefs.use_os_locales", true);
user_pref("widget.gtk.overlay-scrollbars.enabled", false);
user_pref("browser.startup.page", 3);
user_pref("browser.download.useDownloadDir", false);\047 > $_/user.js
#
#Настройка sway.
echo -e "\\033[36mНастройка sway.\\033[0m"
if [ -n "$(clinfo -l)" ];
    then sed -i \047s/#TechnicalSymbolV //\047 ~/.config/sway/config
    else sed -i \047/#TechnicalSymbolV /d\047 ~/.config/sway/config
fi
#
#Настройка звука.
echo -e "\\033[36mНастройка звука.\\033[0m"
soundmass=($(aplay -l | grep -i \047^card\047 | awk \047{print $2}\047 | tr -d \047:\047 | sort -u))
for j in "${soundmass[@]}"
            do
amixer -c "$j" sset Master unmute
amixer -c "$j" sset Speaker unmute
amixer -c "$j" sset Headphone unmute
amixer -c "$j" sset "Auto-Mute Mode" Disabled
amixer -c "$j" sset "HP/Speaker Auto Detect" unmute
            done
alsactl store
#
#Настройка внешнего вида программ.
echo -e "\\033[36mНастройка внешнего вида программ.\\033[0m"
gsettings set org.gnome.desktop.interface gtk-theme "Breeze-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface font-name \047Fantasque Sans Mono, '"$font"'\047
gsettings set org.gnome.desktop.interface document-font-name \047Fantasque Sans Mono Bold Italic '"$font"'\047
gsettings set org.gnome.desktop.interface monospace-font-name \047Fantasque Sans Mono '"$font"'\047
gsettings set org.gnome.desktop.wm.preferences titlebar-font \047Fantasque Sans Mono Bold '"$font"'\047
gsettings set org.gnome.libgnomekbd.indicator font-size '"$font"'
gsettings set org.gnome.meld custom-font \047monospace, '"$font"'\047
gsettings set org.cinnamon.desktop.default-applications.terminal exec \047foot\047
gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg \047-e\047
#
#Запуск демона синхронизации времени.
sudo timedatectl set-ntp true
#
#Cкопирует список пакетов из репозитория Debian.
echo -e "\\033[36mCкопирует список пакетов из репозитория Debian.\\033[0m"
sudo debtap -u
#
#Создание двоичного кэша данных, хранящихся в файлах.desktop и MIME, которые фреймворк KService использует для поиска плагинов, приложений и других сервисов.
echo -e "\\033[36mСоздание двоичного кэша данных, хранящихся в файлах.desktop и MIME, которые фреймворк KService использует для поиска плагинов, приложений и других сервисов.\\033[0m"
kbuildsycoca6
#
#Настройка wine (Позволяет запускать приложения Windows).
echo -e "\\033[36mНастройка wine (Позволяет запускать приложения Windows).\\033[0m"
WINEARCH=win32 winetricks d3dx9
winetricks dxvk
#
#Устанавливаем приложения по умолчанию.
xdg-mime default nemo.desktop inode/directory
xdg-mime default nemo.desktop application/x-directory
xdg-mime default org.mozilla.Thunderbird.desktop x-scheme-handler/mailto
xdg-mime default vlc.desktop video/mp4
xdg-mime default vlc.desktop video/x-matroska
xdg-mime default vlc.desktop video/x-msvideo
xdg-mime default vlc.desktop video/quicktime
xdg-mime default vlc.desktop x-flv
xdg-mime default vlc.desktop x-ms-wmv
xdg-mime default org.geeqie.Geeqie.desktop image/jpeg
xdg-mime default org.geeqie.Geeqie.desktop image/png
xdg-mime default org.geeqie.Geeqie.desktop image/gif
xdg-mime default org.geeqie.Geeqie.desktop image/bmp
xdg-mime default org.geeqie.Geeqie.desktop image/svg+xml
xdg-mime default audacious.desktop audio/mpeg
xdg-mime default audacious.desktop audio/wav
xdg-mime default audacious.desktop audio/ogg
xdg-mime default audacious.desktop audio/x-flac
xdg-mime default audacity.desktop audio/x-ms-wma
xdg-mime default audacity.desktop audio/wav
xdg-mime default org.gnome.font-viewer.desktop font/ttf
xdg-mime default org.gnome.font-viewer.desktop font/otf
xdg-mime default org.x.editor.desktop text/plain
xdg-settings set default-web-browser firefox.desktop
xdg-mime default firefox.desktop text/html
xdg-mime default xreader.desktop application/pdf
xdg-mime default org.gnome.FileRoller.desktop application/zip
xdg-mime default org.gnome.FileRoller.desktop application/x-tar
xdg-mime default org.gnome.FileRoller.desktop application/x-gzip
xdg-mime default org.gnome.FileRoller.desktop application/x-bzip2
#
sudo nft list ruleset
#Удаление временных файлов.
echo -e "\\033[36mУдаление временных файлов.\\033[0m"
sed -i \047/#TechnicalString/d\047 ~/.config/sway/config
sed -i \047s/#TechnicalSymbol//\047 ~/.config/sway/config
#rm ~/archinstall.sh' > /mnt/home/"$username"/archinstall.sh
#
# Обновление системного кэша шрифтов Fontconfig
echo -e "\033[36mОбновление системного кэша шрифтов...\033[0m"
arch-chroot /mnt fc-cache -fv
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
#Настройка virtualbox учитывая хост/гость в Wayland.
echo -e "\033[36mНастройка virtualbox учитывая хост/гость.\033[0m"
GPU_INFO=$(lspci | grep -iE 'vga|3d')
if echo "$GPU_INFO" | grep -iE -q 'vmware svga|virtualbox'; then
    echo -e "\033[36mНастройка системы в режиме ГОСТЯ VirtualBox...\033[0m"
    arch-chroot /mnt systemctl enable vboxservice.service
    # Добавляем пользователя в группу для доступа к общим папкам (Shared Folders)
    arch-chroot /mnt gpasswd -a "$username" vboxsf
    echo "WLR_NO_HARDWARE_CURSORS=1
WLR_RENDERER=pixman
WLR_DRM_NO_MODIFIERS=1" >> /mnt/etc/environment
    echo "exec VBoxClient-all" | tee -a /mnt/home/"$username"/.config/sway/config /mnt/root/.config/sway/config
else
    echo -e "\033[36mНастройка системы в режиме ХОСТА (Эмуляция виртуальных машин)...\033[0m"
    arch-chroot /mnt pacman -Sy virtualbox-host-dkms virtualbox --noconfirm
    arch-chroot /mnt sudo -u "$username" yay -S virtualbox-ext-oracle --noconfirm
    echo "vboxdrv
vboxnetflt
vboxnetadp" > /mnt/etc/modules-load.d/virtualboxhosts.conf
    # Добавляем пользователя в группу управления виртуальными машинами
    arch-chroot /mnt gpasswd -a "$username" vboxusers
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
#Настройка разрешения локального имени хоста (mDNS для Avahi/SANE/CUPS).
echo -e "\033[36mНастройка разрешения локального имени хоста (nsswitch)...\033[0m"
sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /mnt/etc/nsswitch.conf
#
#Обновление часового пояса после подключения к сети через NetworkManager.
echo -e "\033[36mОбновление часового пояса после подключения к сети через NetworkManager.\033[0m"
echo '#!/bin/sh
case "$2" in
    up)
        timedatectl set-timezone "$(curl -f https://ipapi.co/timezone)"
    ;;
esac' > /mnt/etc/NetworkManager/dispatcher.d/09-timezone
#
# Делаем системные скрипты и меню Wofi исполняемыми.
echo -e "\033[36mВыдача прав на исполнение для системных скриптов и меню...\033[0m"
chmod +x /mnt/etc/NetworkManager/dispatcher.d/09-timezone /mnt/home/"$username"/archinstall.sh /mnt/home/"$username"/.config/wofi/menu_help.sh /mnt/home/"$username"/.config/wofi/menu_power.sh /mnt/root/.config/wofi/menu_help.sh /mnt/root/.config/wofi/menu_power.sh
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
#fdisk -l
lsblk -l
