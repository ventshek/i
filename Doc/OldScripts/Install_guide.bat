dd if=/dev/urandom of=/dev/sda bs=4k #status=progress



fdisk /dev/sda 
1 new part of 1MB
1 part 512M efi




cryptsetup luksFormat --type luks1 --use-random -S 1 -s 512 -h sha512 -i 5000 /dev/sda3
cryptsetup open /dev/sda2 cryptlvm

pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm

lvcreate -L 512M vg -n swap
lvcreate -l 100%FREE vg -n root

mkfs.ext4 /dev/vg/root
mkswap /dev/vg/swap

mount /dev/vg/root /mnt
swapon /dev/vg/swap

pacstrap /mnt base linux linux-firmware mkinitcpio lvm2 vi dhcpcd wpa_supplicant nano 

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

/etc/locale.gen
"en_US.UTF-8 UTF-8"

locale-gen

/etc/locale.conf
"LANG=en_US.UTF-8"

/etc/hostname
"hostname"

/etc/hosts
"127.0.0.1 localhost"
"::1 localhost"
"127.0.1.1 myhostname.localdomain myhostname"

nano /etc/mkinitcpio.conf
HOOKS=(base udev autodetect keyboard modconf block encrypt lvm2 filesystems fsck)

passwd

pacman -S grub
/etc/default/grub
"GRUB_ENABLE_CRYPTODISK=y"

blkid
(UUID=/dev/sda2)
GRUB_CMDLINE_LINUX="... cryptdevice=UUID=xxxxxx:cryptlvm root=/dev/vg/root ..."
grub-install --target=i386-pc --recheck /dev/sda

da51153f-a1f3-49df-a4ef-f61a19ffa20e
18700cb5-3314-408b-8f03-960ce48afbd7
342a51b9-c745-4a87-8a2f-bf45a07fe358

grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

mkdir /root/secrets && chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
cryptsetup -v luksAddKey -i 1 /dev/sda3 /root/secrets/crypto_keyfile.bin

/etc/mkinitcpio.conf
"FILES=(/root/secrets/crypto_keyfile.bin)"

mkinitcpio -p linux

/etc/default/grub
"GRUB_CMDLINE_LINUX="
"... cryptdevice=UUID=xxxxxx:cryptlvm root=/dev/vg/root cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"
mkinitcpio -p linux
grub-mkconfig -o /boot/grub/grub.cfg
chmod 700 /boot
exit
reboot

S

useradd -m -G wheel tor? -s /bin/bash user1
passwd user1

pacman -S xfce4 sudo sddm network-manager-applet xfce4-goodies fwbuilder intel-ucode tor nyx
&& torbrowser-launcher


sudo systemctl enable sddm NetworkManager dhcpcd tor

sudo nano /etc/tor/torrc
ControlPort 9051

usermod -a -G tor user1





modprobe -a vboxguest vboxsf vboxvideo
OR
vmtoolsd vmware-vmblock-fuse.service for open-vm-tools




uuidgen --random > GUID.txt

openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/bent=my Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth
sign-efi-sig-list -g "$(< GUID.txt)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/bent=my Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

