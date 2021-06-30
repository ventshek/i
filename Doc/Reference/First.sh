#!/usr/bin/env sh

#          ( O O )
# =======oOO=(_)==OOo======
# arch install script
# author Rinat Sabitov aka histrio
# created: May 2015
# modified: Dec 2016
# =======oOO======OOo======

parted -s /dev/sda -- mklabel msdos \
    mkpart primary ext4 1MiB 100MiB \
    set 1 boot on \
    mkpart primary ext4 100MiB 40GiB \
    mkpart primary linux-swap 40GiB 48GiB\
    mkpart primary ext4 48GiB 100%

mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2
mkswap /dev/sda3
swapon /dev/sda3
mkfs.ext4 /dev/sda4

mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home

pacman -Sy
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base linux linux-firmware

genfstab -U -p /mnt >> /mnt/etc/fstab


#====================================================================
cat <<- EOF > /mnt/second.sh
echo LANG=en_US.UTF-8 > /etc/locale.conf
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc --utc
pacman -Sy
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu
pacman -S  --noconfirm --needed archlinux-keyring
pacman -S  --noconfirm --needed \
    avahi \
    awesome \
    bogofilter \
    ctags \
    cups \
    dbus \
    deadbeef \
    djvulibre \
    firefox \
    flac \
    flake8 \
    git \
    gnupg \
    gparted \
    gvim \
    hplip \
    htop \
    ncdu \
    netctl \
    ntfs-3g \
    shotwell \
    slim \
    slim-themes \
    sudo \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    tmux \
    udevil \
    unzip \
    usbutils \
    vim-runtime \
    vim-spell-en \
    vim-spell-ru \
    vlc \
    xbindkeys \
    xscreensaver \
    xxkb \
    wget \
    zathura \
    zathura-djvu \
    zathura-pdf-mupdf \
    zathura-ps \
    zip \
    zsh \
    xorg-server \
    openssh \
    ttf-dejavu \
    ttf-droid
#userdel rinat
useradd -m -g users -G audio,games,lp,optical,power,scanner,storage,video,wheel -s /bin/zsh rinat
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
pacman -S grub os-prober --noconfirm
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
echo tethys > /etc/hostname
systemctl enable dhcpcd
systemctl enable slim
echo "default_user rinat" >> /etc/slim.conf
echo rinat:password | chpasswd
passwd rinat -e
echo root:password | chpasswd
passwd root -e
EOF
#====================================================================

arch-chroot /mnt /bin/bash -e -x /second.sh
rm /mnt/second.sh
