# init, stage one
# Definitions
passphrase=123
disk=/dev/sda
dev=/dev/sda3
partition=/dev/mapper/cryptlvm
volgroup=gg
swap=/dev/gg/swap
root_dev=/dev/gg/root
efi=/dev/sda2
efi_dir=/mnt/efi
mnt=/mnt
# Update pacman
pacman --noconfirm -Sy
# Install wipe
pacman --noconfirm -S wipe
# Fill with random data
dd if=/dev/urandom of=/dev/sda bs=4k #status=progress
# Wipe the drive
wipe /dev/sda #status=progress
# Partition the drives 
sfdisk --quiet -- "$disk" <<-'EOF'
    label:gpt
    type=21686148-6449-6E6F-744E-656564454649,size=1MiB,attrs=LegacyBIOSBootable,name=bios_boot
    type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B,size=512MiB
    type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
# Setup Luks
echo -en "$passphrase" | cryptsetup luksFormat --type luks1 --use-random -S 1 -s 512 -h sha512 -i 5000 "$dev"
# Open new partition
echo -en "$passphrase" | cryptsetup luksOpen "$dev" cryptlvm
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
# Mount root
mount -- "$root_dev" "$mnt"
# Make efi directory
mkdir -- "$efi_dir"
# Mount swap
swapon -- "$swap"
# Mount EFI
mount -- "$efi" "$efi_dir"
# Pacstrap
pacstrap /mnt base linux-lts top htop efibootmgr base-devel efitools linux-lts-headers e2fsprogs linux-firmware mkinitcpio lvm2 vi dhcpcd wpa_supplicant nano grub sudo xf86-video-vesa xfce4 sddm network-manager-applet fwbuilder intel-ucode tor nyx torbrowser-launcher wget virtualbox virtualbox-host-dkms
# Generate fstab
genfstab -U "$mnt" >> /mnt/etc/fstab
# remove script
rm init.sh
# Chroot
arch-chroot "$mnt"