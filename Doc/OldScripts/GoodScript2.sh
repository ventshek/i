# innit, stage two
# Definitions
userpasswd=changeme
rootpasswd=changeme
root=root
user=user
language=LANG=en_US.UTF-8
localeconf=/etc/locale.conf
hostname=Device
uuid=$(blkid -o value -s UUID /dev/sda3)
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
# Edit Mkinitcpio Files
sed -i 's/FILES=()/FILES=(\/root\/secrets\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
# Run Mkinitcpio 
mkinitcpio -p linux-lts
# Enable Luks boot in Grub
sed -i 's/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
# Uncomment Wheel in sudoers
sudo sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
# Add user to sudoers etc
useradd -m -G wheel -s /bin/bash user
# Add user to vbox
usermod -G vboxusers user
# Set root passwd
echo "$root":"$rootpasswd" | chpasswd
# Set user passwd
echo "$user":"$userpasswd" | chpasswd
# Remove original grub defaults
rm /etc/default/grub
# Rewrite Grub
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
# Install Grub
grub-install --target=x86_64-efi --efi-directory=/efi
# Create Grub config
grub-mkconfig -o /boot/grub/grub.cfg
# Create crypt key for single password boot
mkdir /root/secrets && chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
cryptsetup -v luksAddKey -i 1 /dev/sda3 /root/secrets/crypto_keyfile.bin
# Run Mkinitcpio again
mkinitcpio -p linux-lts
# Run grub config again
grub-mkconfig -o /boot/grub/grub.cfg
# Chmod /boot
chmod 700 /boot
# Grub config again
grub-mkconfig -o /boot/grub/grub.cfg
# Enable NetworkManager
systemctl enable NetworkManager
# Enable dhcpcd
systemctl enable dhcpcd
# Enable tor
systemctl enable tor
# Enable sddm
systemctl enable sddm
# Clear Bash History
history -c
# Remove innit
rm innit