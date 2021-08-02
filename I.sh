#!/bin/bash

modprobe -a vboxguest
modprobe -a vboxsf 
modprobe -a vboxvideo

# Splashpage
options=()
options+=("WGET" "(Alternative Script)")
options+=("No GUI" "(AIO Installer)")
options+=("Exit to shell" "(Installer)")
options+=("Disk Utility" "(Gparted)")
sel=$(whiptail --backtitle "Arch Static.." --title "Select Choice" --menu "" 15 48 4 \
"${options[@]}" 3>&1 1>&2 2>&3)
if [ "${sel}" = "WGET" ]; then
pacman --noconfirm -Sy  wget > /dev/nul
wget https://www.github.com/ventshek/i/raw/main/I.sh
elif [ "${sel}" = "Exit to shell" ]; then
exit
elif [ "${sel}" = "Disk Utility" ]; then
clear
echo "Fetching files..."
pacman --noconfirm -Sy  gdm gparted btrfs-progs-unstable cryptsetup \
dosfstools e2fsprogs exfatprogs fatresize ntfs-3g squashfs-tools konsole \
gtk3 > /dev/nul
cat > /etc/gdm/custom.conf <<'EOS'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=root
EOS
cat > /etc/xdg/autostart/gparted.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=gparted
Exec=/usr/bin/gparted
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
EOS
systemctl enable gdm && systemctl start gdm
exit
clear
elif [ "${sel}" = "No GUI" ]; then
tput setaf 1; echo "Starting Installator"
tput setaf 7; 
else
echo "..."
fi


## User choice and definitions section ##


# FYI
tput setaf 2; echo "## Updating Pacman..."
# Initial Pacman setup
pacman --quiet --noprogressbar --noconfirm -Sy cryptsetup > /dev/nul
echo "..."
echo "Complete..."

# Ask user to choose packages
tput setaf 7; echo ""
echo "Choose one of the following installs..."
echo "1. Desktop install"
echo "2. FTP Server install"
echo "3. Bare bones"
echo "------------------------------------"
read -e -p "
Please type a number, 1,2,3? [Y/n] " P
tput setaf 2; echo "OK"

# Show user the disks available and ask which one
tput setaf 7; echo ""
echo "Disk list....."
echo ""
echo "------------------------------------"
echo ""
sudo lsblk -o name,size
echo ""
echo "------------------------------------"
echo ""
echo -n "Enter installation target disk e.g. 'sda' or 'sdb' [ENTER]: "
read sdx
tput setaf 2; echo "OK"

# Ask user if the want Encryption
tput setaf 7; read -e -p "
Encrypt drive, including boot drive (UEFI)? [Y/n] " E
tput setaf 2; echo "OK"

# Gather passwords from user for disk
if [[ $E == "y" || $E == "Y" || $E == "" ]]; then
tput setaf 7; read -e -p "
Enter disk password for Luks encryption [ENTER]: " luks1
tput setaf 2; echo "OK"
else
tput setaf 2; echo "OK"
fi

# Take info from user for swap and lvm
tput setaf 7; read -e -p "
Enter desired swap in MB (512 minimum) e.g. '512' [ENTER]: " swp
tput setaf 1; echo "Swap size selected = $swp MB"
tput setaf 2; echo "OK"

# Ask user if the want GUI
if [[ $P == "3" || $P == "3" ]]; then 
tput setaf 7; echo "..."
else
tput setaf 7; read -e -p "
Do you need a GUI? [Y/n] " G
fi
tput setaf 2; echo "OK"

# Ask user if they need wipe
tput setaf 7; read -e -p "
Fill drives with random data before install (takes a long time)? [Y/n] " W
tput setaf 2; echo "OK"

# Definitions 
usr=user
rt=root
language=LANG=en_US.UTF-8

# Take input for passwords
tput setaf 7; read -e -p "
Enter your desired device name [ENTER]: " host
tput setaf 2; echo "OK"
tput setaf 7; read -e -p "
Enter disk desired username [ENTER]: " usr
tput setaf 2; echo "OK"
tput setaf 7; read -e -p "
Enter your root password [ENTER]: " rtpw
tput setaf 2; echo "OK"
tput setaf 7; read -e -p "
Enter your user password [ENTER]: " usrpw
tput setaf 2; echo "OK"
tput setaf 7; 

# Definitions of directories
disk=/dev/"$sdx"
efi=/dev/"$sdx"2
dev=/dev/"$sdx"3
partition=/dev/mapper/cyrptlvm
volgroup=vol
swap=/dev/vol/swap
root_dev=/dev/vol/root
mnt=/mnt
efi_dir="$mnt"/efi
fstabdir="$mnt"/etc/fstab
uuid=$(blkid -o value -s UUID /dev/"$dev")
grubcfg=/boot/grub/grub.cfg
PK="$G""$P"


## Disk prep and partitioning section ##


# FYI
tput setaf 2; echo "## All nessesary input acquired..."

# DD all free space if specified
if [[ $W == "y" || $W == "Y" || $W == "" ]]; then
dd if=/dev/urandom of="$disk" bs=4k status=progress
tput setaf 2; echo "## Wipe Complete..."
else
echo "..."
fi
tput setaf 2; echo "## Starting Partitioning..."

# Partitioning options
if [[ $E == "y" || $E == "Y" || $E == "" ]]; then
# Partition the drives
tput setaf 7; sfdisk --quiet --force -- "$disk" <<-'EOF'
    label:gpt
    type=21686148-6449-6E6F-744E-656564454649,size=1MiB,attrs=LegacyBIOSBootable,name=bios_boot
    type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,size=512MiB
    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
# Setup Luks
echo -en "$luks1" | cryptsetup luksFormat --type luks1 --use-random -S 1 -s 512 -h sha512 -i 5000 "$dev"
# Open new partition
echo -en "$luks1" | cryptsetup luksOpen "$dev" cyrptlvm
# Create physical volume
pvcreate "$partition"
# Create volume group
vgcreate "$volgroup" "$partition"
# Create a 512MB swap partition
lvcreate -C y -L"$swp"M "$volgroup" -n swap
# Use the rest of the space for root
lvcreate -l '+100%FREE' "$volgroup" -n root
# Enable the new volumes
vgchange -ay
else
# Partition the drives
tput setaf 7; sfdisk --quiet --force -- "$disk" <<-'EOF'
    label:gpt
    type=21686148-6449-6E6F-744E-656564454649,size=1MiB,attrs=LegacyBIOSBootable,name=bios_boot
    type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,size=512MiB
    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
# Create physical volume
pvcreate "$dev"
# Create volume group
vgcreate "$volgroup" "$partition"
# Create a 512MB swap partition
lvcreate -C y -L"$swp"M "$volgroup" -n swap
# Use the rest of the space for root
lvcreate -l '+100%FREE' "$volgroup" -n root
# Enable the new volumes
vgchange -ay
fi
# FYI
echo ""
tput setaf 2; echo "## All Partitioning Complete..."
tput setaf 7; echo ""

# Format swap
mkswap -- "$swap"
# Format root
mkfs.ext4 -q -L -- "$root_dev"
# Format EFI
mkfs.fat -F32 -- "$efi"
# Mount all disks
mount -- "$root_dev" "$mnt"
mkdir -- "$efi_dir"
swapon -- "$swap"
mount -- "$efi" "$efi_dir"
# FYI
echo ""
tput setaf 2; echo "## Formatting and Mounting Complete..."
tput setaf 7; echo ""


## Pacstrapping Section ## 


tput setaf 2; echo "Starting installation..."
tput setaf 7; echo ""
# Bare bones  
if [[ $PK == "3" || $PK == "3" || $PK == "3" ]]; then

	pacstrap "$mnt" --quiet --noprogressbar --noconfirm \
base linux efibootmgr lvm2 grub efitools cryptsetup \
linux-headers linux-firmware mkinitcpio dosfstools \
wget nano e2fsprogs vi git sudo rkhunter \
dhcpcd wpa_supplicant intel-ucode ufw &> /dev/nul

# Desktop with GUI
elif [[ $PK == "y1" || $PK == "Y1" || $PK == "1" ]]; then

	pacstrap "$mnt" --quiet --noprogressbar --noconfirm \
base linux efibootmgr lvm2 grub efitools cryptsetup \
linux-headers linux-firmware mkinitcpio dosfstools \
wget nano e2fsprogs vi git sudo rkhunter \
dhcpcd wpa_supplicant intel-ucode \
xf86-video-ati xf86-video-intel xf86-video-amdgpu \
xf86-video-nouveau xf86-video-fbdev xf86-video-vesa \
ufw firefox htop sddm xfce4 keepass fuse2 &> /dev/nul

# Server With GUI
elif [[ $PK == "y2" || $PK == "Y2" || $PK == "2" ]]; then

	pacstrap "$mnt" --quiet --noprogressbar --noconfirm \
base linux efibootmgr lvm2 grub efitools cryptsetup \
linux-headers linux-firmware mkinitcpio dosfstools \
wget nano e2fsprogs vi git sudo rkhunter \
dhcpcd wpa_supplicant intel-ucode \
xf86-video-ati xf86-video-intel xf86-video-amdgpu \
xf86-video-nouveau xf86-video-fbdev xf86-video-vesa \
ufw firefox htop sddm xfce4 keepass fuse2 \
vsftpd openssh &> /dev/nul

# Desktop No GUI
elif [[ $PK == "n1" || $PK == "N1" || $PK == "n1" ]]; then

	pacstrap "$mnt" --quiet --noprogressbar --noconfirm \
base linux efibootmgr lvm2 grub efitools cryptsetup \
linux-headers linux-firmware mkinitcpio dosfstools \
wget nano e2fsprogs vi git sudo rkhunter \
dhcpcd wpa_supplicant intel-ucode &> /dev/nul

# Server No GUI
elif [[ $PK == "n2" || $PK == "N2" || $PK == "n2" ]]; then

	pacstrap "$mnt" --quiet --noprogressbar --noconfirm \
base linux efibootmgr lvm2 grub efitools cryptsetup \
linux-headers linux-firmware mkinitcpio dosfstools \
wget nano e2fsprogs vi git sudo rkhunter \
dhcpcd wpa_supplicant intel-ucode \
vsftpd openssh &> /dev/nul
fi

tput setaf 2; echo "## Pacstrap Complete..."

# Generate fstab
tput setaf 7; genfstab -U "$mnt" >> "$fstabdir"


## Chroot Stage ##


# Interpreted variables

cat > /mnt/II.sh <<EOF

E=$E
P=$P
G=$G
usr=$usr
rt=root
rtpw=$rtpw
usrpw=$usrpw
sdx=$sdx
PK=$PK
luks1=$luks1
host=$host
language=LANG=en_US.UTF-8
EOF

# Literal variables

cat >> /mnt/II.sh <<'EOS'
dev=/dev/"$sdx"3
uuid=$(blkid -o value -s UUID /dev/"$sdx"3)
EOS


## Locale and device


cat >> /mnt/II.sh <<'EOS'


## Locale settings and initiation


# Set local time
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime 

# Write to /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen  &> /dev/nul

# Generate locale
locale-gen  &> /dev/nul

# Edit local conf
echo "$language" > /etc/locale.conf

# Write hostname
echo "$host" >> /etc/hostname

# Write hosts
cat > /etc/hosts <<EOF
127.0.0.1 localhost.localdomain localhost $host
::1       localhost.localdomain localhost $host
EOF
EOS


## User specific settings entry


cat >> /mnt/II.sh <<'EOS'

# Generic user setup

sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
useradd -m -d /home/"$usr" -G wheel -s /bin/bash "$usr"
echo "User created..."
echo "$rt":"$rtpw" | chpasswd
echo "$usr":"$usrpw" | chpasswd
EOS


## Stuff for encrypted version

if [[ $E == "y" || $E == "Y" || $E == "" ]]; then
cat >> /mnt/II.sh <<'EOS'

# Add hooks to mkinitcpio

sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux &> /dev/nul

# Rewrite Grub for encryption 
rm /etc/default/grub
cat > /etc/default/grub <<EOF
		# GRUB boot loader configuration

		GRUB_DEFAULT=0
		GRUB_TIMEOUT=5
		GRUB_DISTRIBUTOR="Arch"
		GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
		GRUB_CMDLINE_LINUX="... cryptdevice=UUID=$uuid:cryptlvm root=/dev/vol/root cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"

		# Preload both GPT and MBR modules so that they are not missed
		GRUB_PRELOAD_MODULES="part_gpt part_msdos"

		# Uncomment to enable booting from LUKS encrypted devices
		GRUB_ENABLE_CRYPTODISK=y

		# Set to 'countdown' or 'hidden' to change timeout behavior,
		# press ESC key to display menu.
		GRUB_TIMEOUT_STYLE=menu

		# Uncomment to use basic console
		GRUB_TERMINAL_INPUT=console

		# Uncomment to disable graphical terminal
		#GRUB_TERMINAL_OUTPUT=console

		# The resolution used on graphical terminal
		# note that you can use only modes which your graphic card supports via VBE
		# you can see them in real GRUB with the command vbeinfo
		GRUB_GFXMODE=auto

		# Uncomment to allow the kernel use the same resolution used by grub
		GRUB_GFXPAYLOAD_LINUX=keep

		# Uncomment if you want GRUB to pass to the Linux kernel the old parameter
		# format "root=/dev/xxx" instead of "root=/dev/disk/by-uuid/xxx"
		#GRUB_DISABLE_LINUX_UUID=true

		# Uncomment to disable generation of recovery mode menu entries
		GRUB_DISABLE_RECOVERY=true
EOF

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/efi

# Create Grub config
grub-mkconfig -o /boot/grub/grub.cfg

# Create secrets for single password functionality
mkdir /root/secrets 
chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
echo "$luks1" | cryptsetup -v luksAddKey -i 1 "$dev" /root/secrets/crypto_keyfile.bin
sed -i 's/FILES=()/FILES=(\/root\/secrets\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf

# Run Mkinitcpio again
mkinitcpio -p linux  &> /dev/nul

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/efi &> /dev/nul

# Run grub config again
grub-mkconfig -o /boot/grub/grub.cfg &> /dev/nul

# Change permissions for /boot
chmod 700 /boot
EOS


##  Mkinitcpio and grup setup

else
cat >> /mnt/II.sh <<'EOS'

# Run Mkinitcpio
mkinitcpio -p linux  &> /dev/nul

echo "## Mkinitcpio Complete..."

# Install Grub
grub-install --target=x86_64-efi --efi-directory=/efi &> /dev/nul

# Run grub config
grub-mkconfig -o /boot/grub/grub.cfg > /dev/nul
EOS
fi

## GUI Specific

if [[ $G == "y" || $G == "Y" || $G == "" ]]; then
cat >> /mnt/II.sh <<'EOS'

systemctl enable sddm
EOS
else
echo "..."
fi

cat >> /mnt/II.sh <<'EOS'

# General services

systemctl enable dhcpcd
systemctl enable ufw
pacman --noconfirm -Scc > /dev/nul
EOS


## FTP Server Specific 

if [[ $P == "2" || $P == "2" || $P == "2" ]]; then
cat >> /mnt/II.sh <<'EOS'

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config > /dev/nul

systemctl enable sshd
systemctl enable vsftpd
ufw allow ssh
ufw allow ftp


EOS
else
tput setaf 2; 
fi

#nano /mnt/II.sh

# Start chroot with generated script
arch-chroot /mnt sh II.sh 
#&& rm -rf /mnt/II.sh

# Completion message
tput setaf 2; echo "## Successfully Installed !!!"
tput setaf 3; echo "------------------------------------"
tput setaf 3; echo "Device Name = $host"
echo "Disk Password = $luks1"
echo "Username = $usr"
echo "User Password = $usrpw"
echo "Root password = $rtpw"
if [[ $P == "2" || $P == "2" || $P == "2" ]]; then
echo "SSH IP Address, probably one of these: " 
ip -4 addr show enp2s0 | awk '{print $2}'
ip -4 addr show eth0 | awk '{print $2}'
ip -4 addr show wlan0 | awk '{print $2}'
else 
echo "..."
fi
echo "------------------------------------"

# Ask user for reboot
tput setaf 7; read -e -p "
Reboot? [Y/n] " R
if [[ $R == "y" || $R == "Y" || $R == "" ]]; then
reboot
else
sh I.sh
fi


## Surlpus

#pacman --noconfirm -Sy  xorg xorg-fonts-misc xorg-xinit xterm gparted konsole gdm
#hostnamectl -I | awk '{print $1}'
#ip -4 addr show eth* | grep inet
#Install Grub (BIOS)
#grub-install --target=i386-pc --recheck "$disk"
#Grab stuff && install Yay
#cd / ssh_id="$ip -4 addr show enp2s0 | awk '{print $2}'" ssh_id=$(ip -4 addr show enp2s0)
#git clone https://aur.archlinux.org/yay.git
#mv yay /home/user/
#cd /home/user
#wget https://quantum-mirror.hu/mirrors/pub/whonix/ova/15.0.1.7.3/Whonix-XFCE-15.0.1.7.3.ova
#wget https://quantum-mirror.hu/mirrors/pub/whonix/ova/15.0.1.7.3/Whonix-CLI-15.0.1.7.3.ova
#wget https://github.com/ventshek/i/blob/main/conff.sh
#cd /home/user/yay
#chown -R user:user /home/user/yay
#sudo -u user makepkg --noconfirm -si
#rm -R /home/user/yay
#sudo -u user yay --noprogressbar --noconfirm -Syyu
#sudo -u user yay --noprogressbar --noconfirm -S octopi
#sudo -u user yay --noprogressbar --noconfirm -S sublime-text-3
#sudo -u user yay --noprogressbar --noconfirm -S vmware-workstation
#systemctl enable vmware-usbarbitrator
#systemctl enable vmware
#systemctl enable vmware-networks-server
#modprobe -a vmw_vmci vmmon
#sudo -u user yay --noprogressbar --noconfirm -Scc
# If a vm
#pacman -S open-vm-tools xf86-video-vmware
#systemctl enable vmtoolsd
#systemctl vmware-vmblock-fuse
# Enable services
## pacstrap core command 
## pacstrap base base 
#base linux efibootmgr lvm2 grub efitools \
#linux-headers linux-firmware mkinitcpio \
#wget nano e2fsprogs vi git sudo rkhunter \
#dhcpcd wpa_supplicant intel-ucode \
## All GUI Drivers
#xf86-video-ati xf86-video-intel xf86-video-amdgpu \
#xf86-video-nouveau xf86-video-fbdev xf86-video-vesa \
## GUI specific
#ufw firefox htop sddm xfce4 keepass fuse2 \
#cat > ~/.xinitrc <<EOF
#exec gparted
#EOF
#startx
#cat >> /etc/systemd/system/display-manager.service <<'EOS'
#[Unit]
#Description=GNOME Display Manager
#dev=/dev/"$sdx"3
# replaces the getty
#Conflicts=getty@tty1.service
#After=getty@tty1.service

# replaces plymouth-quit since it quits plymouth on its own
#Conflicts=
#After=

# Needs all the dependencies of the services it's replacing
# pulled from getty@.service and 
# (except for plymouth-quit-wait.service since it waits until
# plymouth is quit, which we do)
#After=rc-local.service plymouth-start.service systemd-user-sessions.service

# GDM takes responsibility for stopping plymouth, so if it fails
# for any reason, make sure plymouth still stops
#OnFailure=plymouth-quit.service

#[Service]
#ExecStart=/usr/bin/gdm
#KillMode=mixed
#Restart=always
#IgnoreSIGPIPE=no
#BusName=org.gnome.DisplayManager
#EnvironmentFile=-/etc/locale.conf
#ExecReload=/bin/kill -SIGHUP $MAINPID
#KeyringMode=shared

#[Install]
#Alias=display-manager.service

#EOS
#ln -s /usr/lib/systemd/system/gdm.service \
#/etc/systemd/system/display-manager.service
