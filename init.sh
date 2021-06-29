# init, stage one
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
pacstrap "$mnt" --quiet --noprogressbar --noconfirm base linux-lts efibootmgr firefox ufw base-devel plasma kde-applications efitools linux-lts-headers go linux-firmware mkinitcpio lvm2 htop wget nano torbrowser-launcher e2fsprogs tor nyx vi git xf86-video-vesa gdm dhcpcd wpa_supplicant grub sudo fwbuilder intel-ucode virtualbox virtualbox-host-dkms keepass xf86-video-ati xf86-video-intel xf86-video-amdgpu xf86-video-nouveau rkhunter xf86-video-fbdev
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