# init, stage one
# Directories
disk=/dev/sda
efi=/dev/sda2
dev=/dev/sda3
partition=/dev/mapper/cryptlvm
volgroup=vol
swap=/dev/vol/swap
root_dev=/dev/vol/root
# Mount points
mnt=/mnt
efi_dir=/mnt/efi
fstabdir=/mnt/etc/fstab
# Script
script=init.sh
# Initial Pacman setup
pacman --quiet --noprogressbar --noconfirm -Sy wipe wget > /dev/nul
# Take input from user
echo -n "Enter disk password [ENTER]: "
read luks1
echo -n "Enter swap in MiB [ENTER]: "
read swp
# Fill with random data
dd if=/dev/urandom of="$disk" bs=4k status=progress
# Wipe the drive
wipe "$disk" status=progress
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
lvcreate -C y -L"$swp"M "$volgroup" -n swap
# Use the rest of the space for root
lvcreate -l '+100%FREE' "$volgroup" -n root
# Enable the new volumes
vgchange -ay
echo "************************All Partitioning Complete************************"
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
echo "************************Formatting and Mounting Complete************************"
# Pacstrap all packages
pacstrap "$mnt" --quiet --noprogressbar --noconfirm base linux-hardened efibootmgr firefox ufw base-devel \
plasma kde-applications efitools linux-hardened-headers go linux-firmware mkinitcpio \
lvm2 htop wget nano torbrowser-launcher e2fsprogs tor nyx vi git xf86-video-vesa sddm \
dhcpcd wpa_supplicant grub sudo fwbuilder intel-ucode virtualbox \
virtualbox-host-dkms keepass xf86-video-ati xf86-video-intel xf86-video-amdgpu \
xf86-video-nouveau rkhunter xf86-video-fbdev gtkmm fuse2 > /dev/nul
echo "************************Pacstrap Complete************************"
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
