# in, stage one
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
pacstrap "$mnt" --quiet --noprogressbar --noconfirm base linux linux-firmware \
mkinitcpio lvm2 vi dhcpcd nano \
dhcpcd open-vm-tools xf86-video-vmware \
linux-headers grub efibootmgr efitools sudo > /dev/nul
echo "************************Pacstrap Complete************************"
# Generate fstab
genfstab -U "$mnt" >> "$fstabdir"
# Print the password for disk
echo "Disk Password = $luks1"
# get and place script
wget https://github.com/ventshek/i/raw/main/it.sh
mv it.sh /mnt
chown -R root:root /mnt/it.sh
# Enter chroot and exec
arch-chroot /mnt sh it.sh
# Exit
exit
