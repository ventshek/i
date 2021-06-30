# intiti, is it not?
# Directories
disk=/dev/sda
efi=/dev/sda2
dev=/dev/sda3
partition=/dev/mapper/cryptlvm
volgroup=gg
swap=/dev/gg/swap
root_dev=/dev/gg/root
# Mount points
mnt=/mnt
efi_dir=/mnt/efi
fstabdir=/mnt/etc/fstab
# Script
script=init.sh
# Initial Pacman setup
pacman --quiet --noprogressbar --noconfirm -Sy wipe wget
echo -n "Enter your luks2 password [ENTER]: "
read luks1
# Fill with random data
# dd if=/dev/urandom of="$disk" bs=4k status=progress
# Wipe the drive
# wipe /dev/sda status=progress
# Partition the drives
sfdisk --quiet --force -- "$disk" <<-'EOF'
    label:gpt
    type=21686148-6449-6E6F-744E-656564454649,size=1MiB,attrs=LegacyBIOSBootable,name=bios_boot
    type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,size=512MiB
    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
echo "************************Initial Partitioning Complete************************"
# Setup Luks
echo -en "$luks1" | cryptsetup luksFormat --type luks1 --use-random -S 1 -s 512 -h sha512 -i 5000 "$dev"
# Open new partition
echo -en "$luks1" | cryptsetup luksOpen "$dev" cryptlvm
# Create physical volume
pvcreate "$partition"
# Create volume group
vgcreate "$volgroup" "$partition"
# Create a 512MB swap partition
lvcreate -C y -L1G "$volgroup" -n swap
# Use the rest of the space for root
lvcreate -l '+100%FREE' "$volgroup" -n root
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
echo "************************All Partitioning Complete************************"
# Pacstrap all packages
pacstrap "$mnt" --quiet --noprogressbar --noconfirm base linux-lts efibootmgr base-devel efitools linux-lts-headers go linux-firmware mkinitcpio lvm2 htop wget nano torbrowser-launcher e2fsprogs tor nyx vi git xf86-video-vesa xfce4 xfce4-goodies sddm network-manager-applet dhcpcd wpa_supplicant grub sudo fwbuilder intel-ucode virtualbox virtualbox-host-dkms
# Generate fstab
genfstab -U "$mnt" >> "$fstabdir"
# Remove script
rm "$script"
# Setup second script
wget https://github.com/ventshek/i/raw/main/innit.sh
mv innit.sh /mnt
# Remove Bash history
history -c
# Print the password for disk
echo "Disk Password = $luks1"
echo '- Running additional setup in chroot.'
arch-chroot -- "$mnt" <<-'EOS'
	# Definitions 
	hostname=Device
	usr=user
	rt=root
	# Language config
	language=LANG=en_US.UTF-8
	localeconf=/etc/locale.conf
	# Blkid command
	uuid=$(blkid -o value -s UUID /dev/sda3)
	# Directories
	grubcfg=/boot/grub/grub.cfg
	# Take input for passwords
	echo -n "Enter your luks2 password [ENTER]: "
	read luks1
	echo -n "Enter your root password [ENTER]: "
	read rtpw
	echo -n "Enter your user password [ENTER]: "
	read usrpw
	# Set local time
	ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
	# Write to /etc/locale.gen
	sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	# Generate locale
	locale-gen
	# Edit local conf
	echo "$language" > /etc/locale.conf
	# Write hostname
	echo "$hostname" >> /etc/hostname
	# Write hosts
	cat > /etc/hosts <<EOF
	127.0.0.1 localhost.localdomain localhost $hostname
	::1       localhost.localdomain localhost $hostname
	EOF
	# Edit Mkinitcpio Hooks
	sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.config
	# Run Mkinitcpio 
	mkinitcpio -p linux-lts
	# Uncomment Wheel in sudoers
	sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
	# Add user to sudoers etc
	useradd -m -d /home/user -g wheel -s /bin/bash "$usr"
	sudo usermod -g tor user
	sudo usermod -g network user
	sudo usermod -g vboxusers user
	# Set root passwd
	echo "$rt":"$rtpw" | chpasswd
	# Set user passwd
	echo "$usr":"$usrpw" | chpasswd
	# Install yay
	git clone https://aur.archlinux.org/yay.git
	cd yay
	sudo -u user makepkg --noconfirm -si
	cd 
	rm /yay
	yay --noprogressbar --noconfirm -Syyu octopi
	# Rewrite Grub
	rm /etc/default/grub
	cat > /etc/default/grub <<EOF
		# GRUB boot loader configuration

		GRUB_DEFAULT=0
		GRUB_TIMEOUT=5
		GRUB_DISTRIBUTOR="Arch"
		GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
		GRUB_CMDLINE_LINUX="... cryptdevice=UUID=$uuid:cryptlvm root=/dev/gg/root cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"

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
	# Add scripts to desktop + make exec
	cat > /home/user/Desktop/Update.sh <<EOF
	#!/bin/bash
	sudo pacman -Syyu
	EOF
	cat > /home/user/Desktop/System.sh <<EOF
	#!/bin/bash
	htop
	EOF
	chmod u+x /home/user/Desktop/Update.sh
	chmod u+x /home/user/Desktop/System.sh
	# Install Grub
	grub-install --target=x86_64-efi --efi-directory=/efi
	# Create Grub config
	grub-mkconfig -o /boot/grub/grub.cfg
	# Create directory for secrets
	mkdir /root/secrets 
	# Make secrets directory
	chmod 700 /root/secrets
	# Create subdirectory for key file
	head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
	# Generate Keys
	echo "$luks1" | cryptsetup -v luksAddKey -i 1 /dev/sda3 /root/secrets/crypto_keyfile.bin
	# Edit Mkinitcpio Files
	sed -i 's/FILES=()/FILES=(\/root\/secrets\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
	# Run Mkinitcpio again
	mkinitcpio -p linux-lts
	# Run grub config again
	grub-mkconfig -o "$grubcfg"
	# Change permissions for /boot
	chmod 700 /boot
	# Clear package managers
	pacman --noconfirm -Scc
	# Enable Systemd
	systemctl enable NetworkManager
	systemctl enable dhcpcd
	systemctl enable tor
	systemctl enable sddm
	# Remove innit
	rm /innit.sh
	# Clear Bash History
	history -c
	# Completion message
	echo "******************Successfully Installed******************"
	echo "Grub Password = $luks1"
	echo "User Password = $usrpw"
EOS
exit