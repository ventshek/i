# innit, stage two
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
disk=/dev/sda
dev=/dev/sda3
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
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
# Run Mkinitcpio
mkinitcpio -p linux-lts
# Uncomment Wheel in sudoers
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
# Add user to sudoers etc
useradd -m -d /home/user -G wheel,tor,network,vboxusers,disk -s /bin/bash "$usr"
# Set root passwd
echo "$rt":"$rtpw" | chpasswd
# Set user passwd
echo "$usr":"$usrpw" | chpasswd
# Grab stuff && install Yay
cd /
git clone https://aur.archlinux.org/yay.git
mv yay /home/user/
cd /home/user
wget https://quantum-mirror.hu/mirrors/pub/whonix/ova/15.0.1.7.3/Whonix-XFCE-15.0.1.7.3.ova
wget https://quantum-mirror.hu/mirrors/pub/whonix/ova/15.0.1.7.3/Whonix-CLI-15.0.1.7.3.ova
cd /home/user/yay
chown -R user:user /home/user/yay
sudo -u user makepkg --noconfirm -si
cd
rm yay* && rm -R .git* && rm PKGBUILD && rm -R pkg && rm -R src
yay --noprogressbar --noconfirm -Syyu octopi sublime-text-3
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
sudo pacman --noprogressbar --noconfirm -Syyu
EOF
cat > /home/user/Desktop/System.sh <<EOF
#!/bin/bash
htop
EOF
chmod u+x /home/user/Desktop/Update.sh
chmod u+x /home/user/Desktop/System.sh
# Install Grub
grub-install --target=x86_64-efi --efi-directory=/efi
# Install Grub (BIOS)
grub-install --target=i386-pc --recheck "$disk"
# Create Grub config
grub-mkconfig -o /boot/grub/grub.cfg
# Create directory for secrets
mkdir /root/secrets 
# Make secrets directory
chmod 700 /root/secrets
# Create subdirectory for key file
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
# Generate Keys
echo "$luks1" | cryptsetup -v luksAddKey -i 1 "$dev" /root/secrets/crypto_keyfile.bin
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
systemctl enable gdm
systemctl enable ufw
# Remove innit
rm /innit.sh
# Clear Bash History
history -c
# Completion message
echo "******************Successfully Installed******************"
echo "Grub Password = $luks1"
echo "User Password = $usrpw"
# Exit
exit