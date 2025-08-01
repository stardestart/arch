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
massallprog=( xorg-server \
xorg-xinit \
xterm \
i3-wm \
polybar \
jgmenu \
perl-anyevent-i3 \
perl-json-xs \
dmenu \
xdm-archlinux \
arch-audit \
rkhunter \
firefox \
firefox-i18n-ru \
firefox-spell-ru \
firefox-ublock-origin \
firefox-dark-reader \
firefox-adblock-plus \
i2pd \
links \
thunderbird \
thunderbird-i18n-ru \
xdg-desktop-portal-gtk \
network-manager-applet \
networkmanager-strongswan \
wireless_tools \
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
haveged \
dbus-broker \
x11vnc \
polkit \
kwalletmanager \
kwallet-pam \
xlockmore \
xautolock \
gparted \
gpart \
exfatprogs \
archlinux-xdg-menu \
ark \
p7zip \
ntfs-3g \
dosfstools \
unzip \
smartmontools \
dolphin \
ifuse \
usbmuxd \
libplist \
libimobiledevice \
curlftpfs \
samba \
kimageformats \
ffmpegthumbnailer \
kdegraphics-thumbnailers \
qt5-imageformats \
kdesdk-thumbnailers \
ffmpegthumbs \
kdenetwork-filesharing \
smb4k \
kclock \
calindori \
papirus-icon-theme \
picom \
redshift \
grc \
flameshot \
dunst \
gnome-themes-extra \
archlinux-wallpaper \
cutefish-wallpapers \
cosmic-wallpapers \
elementary-wallpapers \
xdg-desktop-portal \
xdg-desktop-portal-kde \
feh \
conky \
freetype2 \
ttf-fantasque-sans-mono \
gnome-font-viewer \
neofetch \
alsa-utils \
alsa-plugins \
lib32-alsa-plugins \
alsa-firmware \
alsa-card-profiles \
pulseaudio \
pulseaudio-alsa \
pulseaudio-bluetooth \
pavucontrol-qt \
libcanberra \
lib32-libcanberra \
sound-theme-freedesktop \
xbindkeys \
aspell \
nuspell \
xed \
cheese \
aspell-en \
aspell-ru \
ethtool \
pinta \
vlc \
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
gogglesmm \
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
python-glfw \
lib32-vulkan-validation-layers \
vulkan-utility-libraries \
vulkan-tools \
vulkan-extra-tools \
vulkan-extra-layers \
mesa \
lib32-mesa \
libva-mesa-driver \
mesa-vdpau \
ufw \
usbguard \
libpwquality \
kde-cli-tools \
ntp \
xdg-user-dirs \
geoclue \
rng-tools \
gtk3-nocsd \
hardinfo2 \
hunspell-ru-aot \
hyphen-ru \
mythes-ru \
minq-ananicy-git \
auto-cpufreq \
kde-cdemu-manager \
usbguard-qt \
pa-notify \
birdtray \
kmscon \
qgnomeplatform-qt5 \
adwaita-qt5 \
qgnomeplatform-qt6 \
adwaita-qt6 \
discord \
meld \
kcolorchooser \
kontrast \
telegram-desktop \
cups-xerox-b2xx \
gcompris-qt)
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
pacman -Sy xorg-mkfontscale --noconfirm
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
sed -i "s/ntfs $PARTITION_COLUMN.*/ntfs-3g       nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000       0 0/" /mnt/etc/fstab
#
#Настройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).
echo -e "\033[36mНастройка usbguard (Помогает защитить ваш компьютер от мошеннических USB-устройств).\033[0m"
ln -sf /mnt/usr/lib32/libstdc++.so.6 /usr/lib32/libstdc++.so.6
ln -sf /mnt/usr/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
ln -sf /mnt/usr/lib32/libstdc++.so /usr/lib32/libstdc++.so
ln -sf /mnt/usr/lib/libstdc++.so /usr/lib/libstdc++.so
usbguard generate-policy > /mnt/etc/usbguard/rules.conf
#
#Создание общего конфига загрузки оконного менеджера.
echo -e "\033[36mСоздание общего конфига загрузки оконного менеджера.\033[0m"
mkdir /mnt/root/.config/
echo -e '#Указание на конфигурационные файлы.
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap
#
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
#
#Запуск программ.
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi
#
#Позволяет пользователю root получить доступ к работающему X-серверу.
xhost +si:localuser:root
#
#Автозапуск обоев рабочего стола.
while true; \
do \
feh --bg-fill --randomize --no-fehbg /usr/share/backgrounds/* /usr/share/backgrounds/; \
sleep 300; \
done &
#
#Автозапуск заставки.
xautolock -time 50 -locker "systemctl hibernate" \
-notify 1800 -notifier \
"xlock -mode matrix -delay 10000 -echokeys -echokey '*'" -detectsleep -noclose &
#
#Воспроизведения звука входа в систему.
canberra-gtk-play -i service-login &
#
#Автозапуск i3.
exec i3' | tee /mnt/home/"$username"/.xinitrc /mnt/root/.xinitrc
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
#Создание конфига bash_profile (Настройка Xorg).
echo -e "\033[36mСоздание конфига bash_profile (Настройка Xorg).\033[0m"
echo '[[ -f ~/.profile ]] && . ~/.profile' | tee /mnt/home/"$username"/.bash_profile /mnt/root/.bash_profile
#
#Создание конфига xdg-desktop-portal (Настройка Xdg).
echo -e "\033[36mСоздание конфига xdg-desktop-portal (Настройка Xdg).\033[0m"
echo -e "[preferred]\ndefault=gtk" > /mnt/usr/share/xdg-desktop-portal/portals.conf
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
PS1="\[\e[48;2;249;43;43m\]\[\e[38;2;43;249;43m\] \$\[\e[48;2;249;249;43m\]\
\[\e[38;2;249;43;43m\]\[\e[48;2;249;249;43m\]\[\e[38;2;43;43;249m\]\A\[\e[48;2;43;43;249m\]\
\[\e[38;2;249;249;43m\] \u@\h\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;249m\]\
\[\e[48;2;43;249;43m\]\[\e[38;2;43;43;43m\]\W\[\e[48;2;43;43;43m\]\[\e[0m\]\
\[\e[38;2;43;249;43m\] \[\e[0m\]"
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
export HISTCONTROL="ignoreboth" #Удаляем повторяющиеся записи и записи начинающиеся с пробела (например команды в mc) в .bash_history.
export COLORTERM=truecolor #Включаем все 16 миллионов цветов в эмуляторе терминала.' | tee /mnt/home/"$username"/.bashrc /mnt/root/.bashrc
#
#Создание конфига profile (Настройка Xorg).
echo -e "\033[36mСоздание конфига profile (Настройка Xorg).\033[0m"
echo '[[ -f ~/.bashrc ]] && . ~/.bashrc #Указание на bashrc.
export QT_QPA_PLATFORMTHEME=gnome #Изменение внешнего вида приложений использующих qt.
export QT_STYLE_OVERRIDE=adwaita-dark #Использовать Adwaitа в качестве стиля Qt по умолчанию
export XDG_CURRENT_DESKTOP=gtk
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
export GTK_CSD=0
export LD_PRELOAD=/usr/lib/libgtk3-nocsd.so.0' | tee /mnt/home/"$username"/.profile /mnt/root/.profile
#
#Редактирование конфига сервера уведомлений.
echo -e "\033[36mРедактирование конфига сервера уведомлений.\033[0m"
sed -i "/\[global\]/,/^\[.*\]/ s/gap_size = .*/gap_size = ${font}/" /mnt/etc/dunst/dunstrc
sed -i "/\[global\]/,/^\[.*\]/ s/icon_theme = .*/icon_theme = Papirus-Dark/" /mnt/etc/dunst/dunstrc
sed -i "/\[global\]/ a script = ~/.config/notify_sound.sh" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_low\]/,/^\[.*\]/ s/background = .*/background = \"#2b2b2b\"/" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_low\]/,/^\[.*\]/ s/foreground = .*/foreground = \"#b2b2b2\"/" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_normal\]/,/^\[.*\]/ s/background = .*/background = \"#2b2b2b\"/" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_normal\]/,/^\[.*\]/ s/foreground = .*/foreground = \"#2bf92b\"/" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_critical\]/,/^\[.*\]/ s/background = .*/background = \"#2b2b2b\"/" /mnt/etc/dunst/dunstrc
sed -i "/\[urgency_critical\]/,/^\[.*\]/ s/foreground = .*/foreground = \"#f92b2b\"/" /mnt/etc/dunst/dunstrc
#
#Создание аудиоконфига сервера уведомлений.
echo -e "\033[36mСоздание аудиоконфига сервера уведомлений.\033[0m"
echo '#!/bin/bash
if [ -n "$(echo $@ | grep pa-notify)" ]; then
    canberra-gtk-play -i audio-volume-change;
    elif [ -n "$(echo $@ | grep nm-no-connection)" ]; then
        canberra-gtk-play -i network-connectivity-lost;
    elif [ -n "$(echo $@ | grep nm-device)" ]; then
        canberra-gtk-play -i network-connectivity-established;
    elif [ -n "$(echo $@ | grep -i critical)" ]; then
        canberra-gtk-play -i window-attention;
    else canberra-gtk-play -i message;
fi' | tee /mnt/home/"$username"/.config/notify_sound.sh /mnt/root/.config/notify_sound.sh
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
# Прозрачность Polybar, dmenu, XTerm и заголовков окон.
opacity-rule = [ "80:class_g = \047Polybar\047",
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
xterm*faceName: Fantasque Sans Mono:size='"$font"'
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
Xcursor.size: 24
Xcursor.theme: Adwaita
!
!Включаем Ctrl+V,Ctrl+C.
XTerm*VT100*selectToClipboard: true
XTerm*VT100*translations: #override \
    Shift Ctrl <Key>V: insert-selection(CLIPBOARD) \n\
    Shift Ctrl <Key>C: copy-selection(CLIPBOARD)' | tee /mnt/home/"$username"/.Xresources /mnt/root/.Xresources
#
#Создание директории и конфига i3-wm (Тайловый оконный менеджер).
echo -e "\033[36mСоздание конфига i3-wm (Тайловый оконный менеджер).\033[0m"
mkdir -p /mnt/home/"$username"/.config/i3 /mnt/root/.config/i3
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
# Перечитать файл конфигурации.
bindsym $mod+Shift+c reload
#
# Перезапустить i3 (сохраняет макет/сессию, может использоваться для обновления i3).
bindsym $mod+Shift+r restart
#
# Выход из i3 (выходит из сеанса X).
bindsym $mod+Shift+e exec "i3-nagbar -t warning \\
-m \047Вы действительно хотите выйти из i3? Это завершит вашу сессию X.\047 \\
-b \047Да, выйти из i3\047 \047canberra-gtk-play -i service-logout; i3-msg exit\047"
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
# Шрифт для заголовков окон.
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
# Включить плавающий режим для всех окон calindori.
for_window [class="calindori"] floating enable
#
# Включить плавающий режим для всех окон kclock.
for_window [class="kclock"] floating enable
#
########### Автозапуск программ ###########
#
# Приветствие в течении 10 сек (--no-startup-id убирает курсор загрузки).
exec --no-startup-id notify-send -t 10000 -i user-red-home "☭ Доброго времени суток ☭" \\
"В меню 🛈 -- Шпаргалка по i3wm.";
#
# Сканер уязвимостей (--no-startup-id убирает курсор загрузки).
exec --no-startup-id bash -c \047sudo rkhunter --propupd; sudo rkhunter --update; \\
sudo rkhunter -c --sk --rwo; notify-send -u critical "✊ Сканер уязвимостей ✊" \\
"$(sudo tail -n 17 /var/log/rkhunter.log)"\047
#
# Автозапуск conky.
exec --no-startup-id conky;
#
# Автозапуск polybar.
exec --no-startup-id polybar upbar;
exec --no-startup-id polybar downbar;
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
# Автозапуск copyq.
exec --no-startup-id copyq;
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
exec --no-startup-id sudo -E usbguard-qt;
#
# Автозапуск xbindkeys.
exec --no-startup-id xbindkeys;
#
# Автозапуск dunst.
exec --no-startup-id dunst;
#
# Автозапуск neofetch и обновления.
#TechnicalSymbolexec --no-startup-id bash -c \047sleep 10; \\
#TechnicalSymbol while [[ 1 -gt "$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)" ]]; \\
#TechnicalSymbol do \\
#TechnicalSymbol sleep 5; \\
#TechnicalSymbol done; \\
#TechnicalSymbol sleep 5; \\
#TechnicalSymbol pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-2)}\047\\\047\047)"; \\
#TechnicalSymbol neofetch > /dev/pts/$pts; \\
#TechnicalSymbol arch-audit > /dev/pts/$pts; \\
#TechnicalSymbol pts="$(ls -m /dev/pts | awk -F ", " \047\\\047\047{print $(NF-1)}\047\\\047\047)"; \\
#TechnicalSymbol sudo rm /var/lib/pacman/db.lck > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Suy --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol yay -Suy --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Sc --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol yay -Sc --noconfirm > /dev/pts/$pts; \\
#TechnicalSymbol sudo pacman -Rsn $(pacman -Qdtq) --noconfirm > /dev/pts/$pts\047
#
# Автозапуск pa-notify.
exec --no-startup-id pa-notify;
#
# Автозапуск thunderbird.
exec --no-startup-id birdtray;
#
# Автозапуск часов-напоминалки.
exec --no-startup-id kclockd;
#
# Автозапуск календаря.
exec --no-startup-id calindac;
#
# Автозапуск telegram.
exec --no-startup-id telegram-desktop -startintray -- %u;
#
########### Горячие клавиши запуска программ ###########
#
#Восстановление рабочего стола №1.
bindsym $mod+mod1+1 exec --no-startup-id "i3-msg \047workspace 1: 🏠; \\
append_layout ~/.config/i3/workspace_1.json; exec xterm; exec xterm; \\
exec dolphin; exec xed\047"
exec --no-startup-id "i3-msg \047workspace 1: 🏠; \\
append_layout ~/.config/i3/workspace_1.json; \\
exec xterm; exec xterm; exec dolphin; exec xed\047"
#
# Используйте mod+enter, чтобы запустить терминал.
bindsym $mod+Return exec xterm
#
# Запуск dmenu (программа запуска) с параметрами шрифта, приглашения, цвета фона.
bindsym $mod+d exec --no-startup-id dmenu_run -fn "Fantasque Sans Mono:style=bold:size='"$(($font/2+$font))"'" \\
-p "Поиск программы:" -nb "#2b2b2b" -sf "#2b2bf9" -nf "#2bf92b" -sb "#f92b2b"
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
exec --no-startup-id firefox; #TechnicalString
exec --no-startup-id bash -c \047sleep 10; ~/archinstall.sh > /dev/pts/1\047 #TechnicalString' | tee /mnt/home/"$username"/.config/i3/config /mnt/root/.config/i3/config
#
#Создание конфига Polybar (Панель рабочего стола).
mkdir -p /mnt/home/"$username"/.config/polybar /mnt/root/.config/polybar
echo -e "\033[36mСоздание конфига Polybar (Панель рабочего стола).\033[0m"
echo -e '[bar/upbar]
background = #2b2b2b
foreground = #b2b2b2
font-0 = Fantasque Sans Mono:size='"$font"'
font-1 = Noto Sans Symbols:size='"$font"'
font-2 = Noto Sans Symbols2:size='"$font"'
font-3 = Noto Emoji SemiBold:size='"$font"'
font-4 = Stalinist One:size='"$font"'
locale = ru_RU.UTF-8
modules-left = jgmenu inetbrowser1 inetbrowser2 filebrowser1 filebrowser2 libreoffice1 libreoffice2 xed1 xed2 calculator1 calculator2 pinta1 pinta2 cheese1 cheese2 skanlite1 skanlite2 i2p1 i2p2
modules-center = title
modules-right = date1 date2 date3 date4 pulseaudio printscreen help poweroff
dpi = 0
height = '"$(($font*3))"'
enable-ipc = true

[module/jgmenu]
type = custom/ipc
hook-0 = echo %{T5} Arch Linux ☭ %{T-}
hook-1 = echo %{T5} Arch Linux ☭ %{T-}
format-0 = <label>
format-0-foreground = #f92b2b
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1
click-left = polybar-msg action jgmenu hook 1; sleep 0.1; polybar-msg action jgmenu hook 0; jgmenu --config-file=~/.config/jgmenu/left

[module/inetbrowser1]
type = custom/script
exec = echo " 🌐"
click-left = polybar-msg action inetbrowser1 module_hide; polybar-msg action inetbrowser2 hook 1; sleep 0.1; polybar-msg action inetbrowser2 hook 0; polybar-msg action inetbrowser1 module_show; xdg-open "about:blank"

[module/inetbrowser2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🌐"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1

[module/filebrowser1]
type = custom/script
exec = echo " 🗂"
click-left = polybar-msg action filebrowser1 module_hide; polybar-msg action filebrowser2 hook 1; sleep 0.1; polybar-msg action filebrowser2 hook 0; polybar-msg action filebrowser1 module_show; xdg-open .

[module/filebrowser2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🗂"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1

[module/libreoffice1]
type = custom/script
exec = echo " 🗋"
click-left = polybar-msg action libreoffice1 module_hide; polybar-msg action libreoffice2 hook 1; sleep 0.1; polybar-msg action libreoffice2 hook 0; polybar-msg action libreoffice1 module_show; libreoffice

[module/libreoffice2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🗋"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1

[module/xed1]
type = custom/script
exec = echo " 📃"
click-left = polybar-msg action xed1 module_hide; polybar-msg action xed2 hook 1; sleep 0.1; polybar-msg action xed2 hook 0; polybar-msg action xed1 module_show; xed

[module/xed2]
type = custom/ipc
hook-0 =
hook-1 = echo " 📃"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1

[module/calculator1]
type = custom/script
exec = echo " 🖩"
click-left = polybar-msg action calculator1 module_hide; polybar-msg action calculator2 hook 1; sleep 0.1; polybar-msg action calculator2 hook 0; polybar-msg action calculator1 module_show; kalgebra

[module/calculator2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🖩"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b

[module/pinta1]
type = custom/script
exec = echo " 🎨"
click-left = polybar-msg action pinta1 module_hide; polybar-msg action pinta2 hook 1; sleep 0.1; polybar-msg action pinta2 hook 0; polybar-msg action pinta1 module_show; pinta

[module/pinta2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🎨"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b

[module/cheese1]
type = custom/script
exec = echo " 📸"
click-left = polybar-msg action cheese1 module_hide; polybar-msg action cheese2 hook 1; sleep 0.1; polybar-msg action cheese2 hook 0; polybar-msg action cheese1 module_show; cheese

[module/cheese2]
type = custom/ipc
hook-0 =
hook-1 = echo " 📸"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b

[module/skanlite1]
type = custom/script
exec = echo " 🖨️"
click-left = polybar-msg action skanlite1 module_hide; polybar-msg action skanlite2 hook 1; sleep 0.1; polybar-msg action skanlite2 hook 0; polybar-msg action skanlite1 module_show; skanlite

[module/skanlite2]
type = custom/ipc
hook-0 =
hook-1 = echo " 🖨️"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b

[module/i2p1]
type = custom/script
exec = echo " I2P"; if [ -n "$(pidof i2pd)" ]; then polybar-msg action i2p1 module_hide; polybar-msg action i2p2 hook 1; else polybar-msg action i2p2 hook 0; polybar-msg action i2p1 module_show; fi
click-left = ~/.config/i2p/index_i2p.sh

[module/i2p2]
type = custom/ipc
hook-0 =
hook-1 = echo " I2P"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
click-left = xlinks -g -socks-proxy 127.0.0.1:4447 ~/.config/i2p/index.html
click-right = kill "$(pidof i2pd)"; polybar-msg action i2p2 hook 0; polybar-msg action i2p1 module_show

[module/title]
type = internal/xwindow
format = ☭ <label> %{F#f92b2b}☭
label = %{F#ffa500}%class%%{F#f92b2b} ➤%{F#ffa500} %title%
format-foreground = #f92b2b
format-margin = 1
label-maxlen = '"$(($font*10))"'

[module/date1]
type = custom/script
format-margin = 1
exec = date "+%H:%M:%S"
interval = 0.3
click-left = polybar-msg action date1 module_hide; polybar-msg action date2 hook 1; sleep 0.1; polybar-msg action date2 hook 0; polybar-msg action date1 module_show; kclock

[module/date2]
type = custom/ipc
hook-0 =
hook-1 = date "+%H:%M:%S"
format-0-margin = 1
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
format-1-margin = 1
initial = 1

[module/date3]
type = custom/script
exec = date "+%A, %d %B %Y"
interval = 0.3
click-left = polybar-msg action date3 module_hide; polybar-msg action date4 hook 1; sleep 0.1; polybar-msg action date4 hook 0; polybar-msg action date3 module_show; calindori

[module/date4]
type = custom/ipc
hook-0 =
hook-1 = date "+%A, %d %B %Y"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1

[module/pulseaudio]
type = internal/pulseaudio
reverse-scroll = false
format-volume = %{F#f92b2b} ☭ %{F-}<ramp-volume><label-volume>%{F#f92b2b} ☭ %{F-}
label-muted = %{F#f92b2b} ☭ %{F-}🔇00%%{F#f92b2b} ☭ %{F-}
label-muted-foreground = #666
ramp-volume-0 = 🔈
ramp-volume-1 = 🔉
ramp-volume-2 = 🔊
click-right = pavucontrol-qt

[module/printscreen]
type = custom/ipc
hook-0 = echo ⎙
hook-1 = echo ⎙
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1
click-left = polybar-msg action printscreen hook 1; sleep 0.1; import ~/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png; polybar-msg action printscreen hook 0

[module/help]
type = custom/ipc
hook-0 = echo " 🛈"
hook-1 = echo " 🛈"
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1
click-left = polybar-msg action help hook 1; sleep 0.1; polybar-msg action help hook 0; jgmenu --csv-file=~/.config/jgmenu/help.csv --config-file=~/.config/jgmenu/right

[module/poweroff]
type = custom/ipc
hook-0 = echo " ⏻ "
hook-1 = echo " ⏻ "
format-1 = <label>
format-1-background = #283544
format-1-foreground = #2bf92b
initial = 1
click-left = polybar-msg action poweroff hook 1; sleep 0.1; polybar-msg action poweroff hook 0; jgmenu --csv-file=~/.config/jgmenu/poweroff.csv --config-file=~/.config/jgmenu/right

[bar/downbar]
background = #2b2b2b
foreground = #b2b2b2
font-0 = Fantasque Sans Mono:size='"$font"'
font-1 = Noto Sans Symbols:size='"$font"'
font-2 = Noto Sans Symbols2:size='"$font"'
font-3 = Noto Emoji SemiBold:size='"$font"'
separator = "%{F#f92b2b} ☭ %{F-}"
locale = ru_RU.UTF-8
modules-left = i3
modules-right = cpu memory netline xkeyboard tray battery
dpi = 0
height = '"$(($font*3))"'
enable-ipc = true
bottom = true
scroll-up = "#i3.prev"
scroll-down = "#i3.next"

[module/i3]
type = internal/i3
show-urgent = true
label-focused-foreground = #2bf92b
label-focused-background = #283544
label-focused-underline = #f92b2b
label-urgent-foreground = #2b2b2b
label-urgent-background = #f92b2b
label-separator = |
label-separator-foreground = #f92b2b

[module/cpu]
type = internal/cpu
interval = 0.5
warn-percentage = 95
label = %percentage%% CPU
label-warn = %{F#000000}%{B#f92b2b}%percentage%%CPU%{F-}%{B-}

[module/memory]
type = internal/memory
interval = 3
warn-percentage = 95
label = 💾: %gb_used%/%gb_free%
label-warn = %{F#000000}%{B#f92b2b}💾: %gb_used%/%gb_free%%{F-}%{B-}

[module/netline]
type = custom/script
exec = netline="| "; netmas="$(nmcli -f GENERAL.DEVICE device show | awk \047!/lo/ && !/^$/ {print $2}\047)"; for word in $netmas; do netline+="$word: "$(nmcli -f IP4.ADDRESS device show "$word" | awk \047{print $2}\047)" | "; done; echo $netline
interval = 1

[module/xkeyboard]
type = internal/xkeyboard
format = <label-layout><label-indicator>
format-spacing = 0
label-layout = %icon%
label-layout-padding = 1
label-layout-background = #283544
label-layout-foreground = #ffffff
layout-icon-0 = ru;RU
layout-icon-1 = us;EN
label-indicator-on-capslock = %{F#ffffff}%{B#283544}C%{F-}%{B-}
label-indicator-off-capslock = %{B#283544}c%{B-}
label-indicator-on-numlock = %{F#ffffff}%{B#283544}N%{F-}%{B-}
label-indicator-off-numlock = %{B#283544}n%{B-}
label-indicator-on-scrolllock = %{F#ffffff}%{B#283544}S%{F-}%{B-}
label-indicator-off-scrolllock = %{B#283544}s%{B-}

[module/tray]
type = internal/tray

[module/battery]
type = internal/battery
full-at = 99
low-at = 5
; $ ls -1 /sys/class/power_supply/
battery = BAT0
adapter = ADP1
format-charging = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 
bar-capacity-width = 10
animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-framerate = 750
animation-discharging-0 = 
animation-discharging-1 = 
animation-discharging-2 = 
animation-discharging-3 = 
animation-discharging-4 = 
animation-discharging-framerate = 500
animation-low-0 = !
animation-low-1 =
animation-low-framerate = 200' | tee /mnt/home/"$username"/.config/polybar/config.ini /mnt/root/.config/polybar/config.ini
#
#Создание скрипта который запускает i2p сеть и введет локальную адресную книгу.
mkdir -p /mnt/home/"$username"/.config/i2p /mnt/root/.config/i2p
echo '#!/bin/bash
# Запускаем I2P Daemon в фоновом режиме.
i2pd --daemon
#
# Цикл, который будет выполняться, пока не будет успешного ответа от указанного URL.
while ! curl -s --socks5-hostname 127.0.0.1:4447 http://flibusta.i2p/; do
    # Отправляем уведомление о том, что I2P туннели настраиваются.
    notify-send --replace-id=9696 -t 5000 -i network-transmit-receive "Настройка I2P туннелей" "Пожалуйста, подождите, идет настройка соединения..."
    # Ждем 5 секунд перед следующей попыткой.
    sleep 5
done
#
# Уведомление о загрузке списка хостов.
notify-send --replace-id=9696 -i document-open "Загрузка списка хостов" "Пожалуйста, подождите, идет загрузка данных..."
# Объявляем массив для адресной книги.
declare -a addressbook
#
# Загружаем список хостов из двух источников и обрабатываем их.
mapfile -t addressbook < <(
    cat <(curl -s -x http://127.0.0.1:4444 http://identiguy.i2p/hosts.txt) \
        <(curl -s -x http://127.0.0.1:4444 http://isitup.i2p/hosts.txt) |
    # Удаляем строки с "=" и комментарии.
    sed -e "s/=\(.*\)//" -e "/^#/d" | sort -u
)
#
# Уведомление об открытии браузера.
notify-send --replace-id=9696 -t 5000 -i browser "Открытие браузера" "Запускаем браузер xlinks для доступа к I2P..."
sleep 50; xlinks -g -socks-proxy 127.0.0.1:4447 ~/.config/i2p/index.html &
#
# Уведомление о создании адресной книги I2P.
notify-send --replace-id=9696 -t 5000 -i document-new "Создание адресной книги I2P" "Обновите страницу браузера с помощью CTRL+R после завершения."
# Удаляем ненужные строки из index.html.
sed -i "/<\/ol>\|<\/body>\|<\/html>/d" ~/.config/i2p/index.html
#
# Перебираем все адреса в адресной книге.
for i in "${!addressbook[@]}"; do
    # Проверяем, есть ли адрес уже в index.html.
    if ! grep --color=never -q -E "${addressbook[i]}" ~/.config/i2p/index.html || grep --color=never -q -E "http://${addressbook[i]}</a> — </li>" ~/.config/i2p/index.html; then
        # Если адреса нет, добавляем его в index.html.
        if curl --max-time 30 -s -x http://127.0.0.1:4444 -H "Range: bytes=0-1000" "http://${addressbook[i]}" |
        grep --color=never -E "<title>([^<]*)</title>" && ! curl --max-time 30 -s -x http://127.0.0.1:4444 -I "http://${addressbook[i]}" |
        grep --color=never -E "Server Error"; then
            echo -e "<li><a href=\"http://${addressbook[i]}\">http://${addressbook[i]}</a> — \
"$(curl --max-time 100 -s -x http://127.0.0.1:4444 -H "Range: bytes=0-1000" http://"${addressbook[i]}" |
            grep --color=never -E "<title>([^<]*)</title>" |
            sed -n "s/.*<title>\(.*\)<\/title>.*/\1/p")"</li>" >> ~/.config/i2p/index.html
            notify-send --replace-id=9696 -i document-new "${addressbook[i]}" "Добавлено в адресную книгу"
        else
            notify-send --replace-id=9696 -i dialog-warning "${addressbook[i]}" "Не удалось получить заголовок"
        fi
    else
        # Если адрес не добавляется, выводим сообщение.
        notify-send --replace-id=9696 -i dialog-information "${addressbook[i]}" "Уже есть в адресной книге"
    fi
done
# Добавляем закрывающие теги в index.html.
echo -e "</ol>\n</body>\n</html>" >> ~/.config/i2p/index.html' | tee /mnt/home/"$username"/.config/i2p/index_i2p.sh /mnt/root/.config/i2p/index_i2p.sh
echo -e "<html>\n<head>\n<title>Index I2P</title>\n</head>\n<body>\n<ol>\n</ol>\n</body>\n</html>" | tee /mnt/home/"$username"/.config/i2p/index.html /mnt/root/.config/i2p/index.html
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
});' > /mnt/etc/polkit-1/rules.d/50-blueman.rules
#
#Настройка polkit (Фреймворк для управления общесистемными привилегиями) для принтеров.
echo -e "\033[36mНастройка polkit (Фреймворк для управления общесистемными привилегиями) для принтеров.\033[0m"
echo 'polkit.addRule(function(action, subject) {
    if (action.id == "org.opensuse.cupspkhelper.mechanism.all-edit" &&
        subject.isInGroup("wheel")){
        return polkit.Result.YES;
    }
});' > /mnt/etc/polkit-1/rules.d/51-allow-passwordless-printer-admin.rules
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
}' | tee /mnt/home/"$username"/.config/i3/workspace_1.json /mnt/root/.config/i3/workspace_1.json
#
#Создание подсказки.
echo -e "\033[36mСоздание подсказки.\033[0m"
echo '#
Win+Enter -- Запустить терминал.
Win+D -- Запуск dmenu (программа запуска).
Win+F1 -- Запустить firefox.
Win+Shift+Q -- Закрыть окно в фокусе.
Print Screen -- Снимок экрана.
#
🌐 -- Запустить firefox.
🗂 -- Запустить Dolphin.
🗋 -- Запустить office.
📃 -- Запустить блокнота.
🖩 -- Запустить калькулятор.
🎨 -- Запустить pinta.
📸 -- Запустить cheese.
🖨️ -- Запустить skanlite.
I2P -- Запуск I2Pd (ПКМ открытие браузера).
⎙ -- Снимок экрана/Ножницы.
🛈 -- Эффекты и мониторинг.
⏻ -- Управление сессией.
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
Win+Alt-left+1 -- Восстановление рабочего стола №1.' > /mnt/help.txt
#
#Создание директории и конфига gtk (Внешний вид gtk программ).
echo -e "\033[36mСоздание конфига gtk (Внешний вид gtk программ).\033[0m"
mkdir -p /mnt/etc/{gtk-3.0,gtk-4.0}
echo '[Settings]
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-name=Adwaita
gtk-font-name=Fantasque Sans Mono Bold Italic '"$font"'
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Adwaita-dark
gtk-decoration-layout=menu:
gtk-overlay-scrolling=false' | tee /mnt/etc/gtk-3.0/settings.ini /mnt/etc/gtk-4.0/settings.ini
echo 'gtk-application-prefer-dark-theme="true"
gtk-cursor-theme-name="Adwaita"
gtk-font-name="Fantasque Sans Mono Bold Italic '"$font"'"
gtk-icon-theme-name="Papirus-Dark"
gtk-theme-name="Adwaita-dark"
gtk-decoration-layout=menu:' > /mnt/usr/share/gtk-2.0/gtkrc
#
#Создание директории и конфига jgmenu.
echo -e "\033[36mСоздание конфига jgmenu.\033[0m"
mkdir -p /mnt/home/"$username"/.config/jgmenu /mnt/root/.config/jgmenu
echo '# Оставлять меню открытым при потере фокуса (0 - false, 1 - true)
stay_alive = 0
# Команда для запуска терминала
terminal_exec = xterm
# Аргументы для запуска терминала
terminal_args = -e
# Количество столбцов в меню
columns = 1
# Горизонтальное выравнивание меню (left, center, right)
menu_halign = left
# Вертикальное выравнивание меню (top, center, bottom)
menu_valign = top
# Вертикальный отступ меню
menu_margin_y = '"$(($font*4))"'
# Тема иконок
icon_theme = Papirus-Dark
#Размер иконок в пикселях
icon_size = '"$(($font*2))"'
# Открывать подменю по клику (true/false)
click_to_open = false
# Шрифт для текста в меню
font = Fantasque Sans Mono '"$font"'
# Цвет фона меню
color_menu_bg = #2b2b2b
# Цвет текста в меню
color_norm_fg = #b2b2b2
# Цвет фона для выделенного элемента
color_sel_bg = #283544
# Цвет текста для выделенного элемента
color_sel_fg = "#ffffff"' | tee /mnt/home/"$username"/.config/jgmenu/left /mnt/root/.config/jgmenu/left /mnt/home/"$username"/.config/jgmenu/right /mnt/root/.config/jgmenu/right
sed -i 's/menu_halign = left/menu_halign = right/' /mnt/home/"$username"/.config/jgmenu/right
sed -i 's/menu_halign = left/menu_halign = right/' /mnt/root/.config/jgmenu/right
echo -e 'Графические эффекты,bash -c \047if [ -n "$(pidof picom)" ]; then killall picom; else picom -b; fi\047,/usr/share/icons/Papirus-Dark/16x16/apps/blackmagicraw-speedtest.svg
Системный монитор,bash -c "sed -i \047s/own_window_type/--own_window_type/\047 ~/.config/conky/conky.conf; sed -i \047s/----//\047 ~/.config/conky/conky.conf",/usr/share/icons/Papirus-Dark/16x16/apps/conky.svg
Подсказка,xed /help.txt,/usr/share/icons/Papirus/16x16/apps/help-browser.svg' | tee /mnt/home/"$username"/.config/jgmenu/help.csv /mnt/root/.config/jgmenu/help.csv
echo -e 'Выход из i3wm,i3-nagbar -t warning -m \047Вы действительно хотите выйти из i3? Это завершит вашу сессию X.\047 -b \047Да! выйти из i3\047 \047canberra-gtk-play -i service-logout; i3-msg exit\047,/usr/share/icons/Papirus-Dark/16x16/actions/application-exit.svg
Перезагрузка,systemctl reboot,/usr/share/icons/Papirus/16x16/apps/system-reboot.svg
Завершение работы,systemctl poweroff,/usr/share/icons/Papirus-Dark/16x16/apps/system-shutdown.svg' | tee /mnt/home/"$username"/.config/jgmenu/poweroff.csv /mnt/root/.config/jgmenu/poweroff.csv
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
PreviewHiddenItems=true' >> /mnt/home/"$username"/.config/smb4krc
#
#Создание конфига copyq.
echo -e "\033[36mСоздание конфига copyq.\033[0m"
mkdir -p /mnt/home/"$username"/.config/copyq/
echo -e '[Options]\ncheck_clipboard=true\ncheck_selection=true\ncopy_clipboard=true\ncopy_selection=true' |
tee /mnt/home/"$username"/.config/copyq/copyq.conf
#
#Создание общего конфига xbindkeys (Настройка мультимедийных клавиш).
echo -e "\033[36mСоздание общего конфига xbindkeys (Настройка мультимедийных клавиш).\033[0m"
echo -e '# Увеличить громкость.
    "pactl set-sink-volume @DEFAULT_SINK@ +1000"
        XF86AudioRaiseVolume
# Уменьшить громкость.
    "pactl set-sink-volume @DEFAULT_SINK@ -1000"
        XF86AudioLowerVolume
# Отключить звук.
    "pactl set-sink-mute @DEFAULT_SINK@ toggle"
        XF86AudioMute
# Отключить микрофон.
    "pactl set-source-mute @DEFAULT_SOURCE@ toggle"
        XF86AudioMicMute
# Открыть калькулятор.
    "kalgebra"
        Mod2 + XF86Calculator
# Открыть почту.
    "thunderbird"
        Mod2 + XF86Mail' | tee /mnt/home/"$username"/.xbindkeysrc /mnt/root/.xbindkeysrc
#
#Редактирование конфига nanorc.
echo -e "\033[36mРедактирование конфига nanorc.\033[0m"
echo 'include "/usr/share/nano-syntax-highlighting/*.nanorc"' >> /mnt/etc/nanorc
sed -i 's/# set autoindent/set autoindent/' /mnt/etc/nanorc
sed -i 's/# set linenumbers/set linenumbers/' /mnt/etc/nanorc
sed -i 's/# set minibar/set minibar/' /mnt/etc/nanorc
sed -i 's/# set positionlog/set positionlog/' /mnt/etc/nanorc
sed -i 's/# set softwrap/set softwrap/' /mnt/etc/nanorc
sed -i 's/# set tabsize 8/set tabsize 4/' /mnt/etc/nanorc
sed -i 's/# set tabstospaces/set tabstospaces/' /mnt/etc/nanorc
sed -i 's/# set titlecolor bold,white,blue/set titlecolor bold,white,blue/' /mnt/etc/nanorc
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
arch-chroot /mnt systemctl disable dbus getty@tty1.service
arch-chroot /mnt systemctl enable acpid bluetooth fancontrol NetworkManager reflector.timer \
xdm-archlinux dhcpcd avahi-daemon ananicy haveged dbus-broker rngd auto-cpufreq smartd smb \
saned.socket cups.socket x11vnc ufw auditd usbguard ntpd kmsconvt@tty1.service
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
#Настройка picom (Автономный композитор для Xorg).
echo -e "\\033[36mНастройка picom (Автономный композитор для Xorg).\\033[0m"
if [ -n "$(clinfo -l)" ];
    then sed -i \047s/#TechnicalSymbol //\047 ~/.config/picom.conf
    else sed -i \047/#TechnicalSymbol /d\047 ~/.config/picom.conf
fi
#
#Настройка звука.
echo -e "\\033[36mНастройка звука.\\033[0m"
soundmass=($(pacmd list-sinks | grep -i name: | awk \047{print $2}\047))
for (( j=0, i=1; i<="${#soundmass[*]}"; i++, j++ ))
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
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface font-name \047Fantasque Sans Mono, '"$font"'\047
gsettings set org.gnome.desktop.interface document-font-name \047Fantasque Sans Mono Bold Italic '"$font"'\047
gsettings set org.gnome.desktop.interface monospace-font-name \047Fantasque Sans Mono '"$font"'\047
gsettings set org.gnome.desktop.wm.preferences titlebar-font \047Fantasque Sans Mono Bold '"$font"'\047
gsettings set org.gnome.libgnomekbd.indicator font-size '"$font"'
gsettings set org.gnome.meld custom-font \047monospace, '"$font"'\047
#
#Проверка наличия touchpad.
echo -e "\\033[36mПроверка наличия touchpad.\\033[0m"
if [ -n "$(xinput list | grep -i touchpad)" ]; then
sudo pacman -S xf86-input-libinput --noconfirm
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
echo -e "\\033[36mНастройка брандмауэра.\\033[0m"
sudo ufw default deny
sudo ufw allow from 192.168.0.0/24
sudo ufw allow Deluge
sudo ufw limit ssh
sudo ufw allow 5900
sudo ufw allow 5353
sudo ufw enable
sudo sed -i \047:a;s/# End required lines/# End required lines\n-A ufw-before-forward -i wg0 -j ACCEPT\n-A ufw-before-forward -o wg0 -j ACCEPT/\047 /etc/ufw/before.rules
sudo sed -i \047s/#net\/ipv4\/ip_forward=1/net\/ipv4\/ip_forward=1/\047 /etc/ufw/sysctl.conf
sudo sed -i \047s/#net\/ipv6\/conf\/default\/forwarding=1/net\/ipv6\/conf\/default\/forwarding=1/\047 /etc/ufw/sysctl.conf
sudo sed -i \047s/#net\/ipv6\/conf\/all\/forwarding=1/net\/ipv6\/conf\/all\/forwarding=1/\047 /etc/ufw/sysctl.conf
#
#Установка переменных окружения.
echo -e "\\033[36mУстановка переменных окружения.\\033[0m"
sudo bash -c \047echo "GTK_USE_PORTAL=1
XDG_MENU_PREFIX=arch-" >> /etc/environment\047
#
#Включение службы redshift (Регулирует цветовую температуру вашего экрана).
echo -e "\\033[36mВключение службы redshift (Регулирует цветовую температуру вашего экрана).\\033[0m"
systemctl --user enable redshift-gtk
systemctl --user start redshift-gtk
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
xdg-mime default org.kde.dolphin.desktop inode/directory application/x-directory
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
xdg-mime default gogglesmm.desktop audio/mpeg
xdg-mime default gogglesmm.desktop audio/wav
xdg-mime default gogglesmm.desktop audio/ogg
xdg-mime default gogglesmm.desktop audio/x-flac
xdg-mime default audacity.desktop audio/x-ms-wma
xdg-mime default audacity.desktop audio/wav
xdg-mime default org.gnome.font-viewer.desktop font/ttf
xdg-mime default org.gnome.font-viewer.desktop font/otf
xdg-mime default org.x.editor.desktop text/plain
xdg-settings set default-web-browser firefox.desktop
xdg-mime default firefox.desktop text/html
xdg-mime default xreader.desktop application/pdf
xdg-mime default org.kde.ark.desktop application/zip
xdg-mime default org.kde.ark.desktop application/x-tar
xdg-mime default org.kde.ark.desktop application/x-gzip
xdg-mime default org.kde.ark.desktop application/x-bzip2
#
xset +fp /usr/share/fonts/TTF
xset +fp /usr/share/fonts/google
#Удаление временных файлов.
echo -e "\\033[36mУдаление временных файлов.\\033[0m"
sed -i \047/#TechnicalString/d\047 ~/.config/i3/config
sed -i \047s/#TechnicalSymbol//\047 ~/.config/i3/config
#rm ~/archinstall.sh' > /mnt/home/"$username"/archinstall.sh
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
arch-chroot /mnt pacman -Sy virtualbox-host-dkms virtualbox --noconfirm
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
        timedatectl set-timezone "$(curl -f https://ipapi.co/timezone)"
    ;;
esac' > /mnt/etc/NetworkManager/dispatcher.d/09-timezone
#
#Делаем xinitrc, 09-timezone и archinstall.sh исполняемыми.
echo -e "\033[36mДелаем xinitrc, 09-timezone и archinstall.sh исполняемыми.\033[0m"
chmod +x /mnt/etc/NetworkManager/dispatcher.d/09-timezone /mnt/home/"$username"/.xinitrc /mnt/home/"$username"/archinstall.sh /mnt/root/.xinitrc /mnt/home/"$username"/.config/notify_sound.sh /mnt/root/.config/notify_sound.sh /mnt/home/"$username"/.config/i2p/index_i2p.sh /mnt/root/.config/i2p/index_i2p.sh
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
#Настройка сканера уязвимостей rkhunter.
echo -e "\033[36mНастройка сканера уязвимостей rkhunter.\033[0m"
echo -e "SCRIPTWHITELIST=/usr/bin/egrep\nSCRIPTWHITELIST=/usr/bin/fgrep\nSCRIPTWHITELIST=/usr/bin/ldd\nSCRIPTWHITELIST=/usr/bin/vendor_perl/GET" >> /mnt/etc/rkhunter.conf
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
