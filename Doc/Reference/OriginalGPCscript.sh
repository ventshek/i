#!/bin/bash
# Copyright 2018 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eEuo pipefail
trap 'echo "Error: \`$BASH_COMMAND\` exited with status $?"' ERR

if (( EUID != 0 )); then
	echo 'This script must be run with root privileges.'
	exit 1
fi

# Setup cleanup trap to remove all temporary data.
cleanup() {
	echo '- Cleaning up.'
	[[ ${mount_dir:-} ]] && umount "$mount_dir"
	[[ ${loop_dev:-} ]] && losetup --detach "$loop_dev"
	[[ ${work_dir:-} ]] && rm -r "$work_dir"
	return 0
}
trap cleanup EXIT

echo '- Creating an empty raw disk image.'
work_dir=$(mktemp --directory --tmpdir="$PWD" build-arch-gce.XXX)
disk_raw=$work_dir/disk.raw
truncate --size=10G -- "$disk_raw"

echo '- Setting up a loop device and partitioning the image.'
loop_dev=$(losetup --find --partscan --show -- "$disk_raw")
sfdisk --quiet -- "$loop_dev" <<-'EOF'
	label:gpt
	type=21686148-6449-6E6F-744E-656564454649,size=1MiB,attrs=LegacyBIOSBootable,name=bios_boot
	type=4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709,name=root
EOF

echo '- Formatting the root partition.'
root_dev=${loop_dev}p2
mkfs.ext4 -q -L root -- "$root_dev"

echo '- Mounting the root partition.'
mount_dir=$work_dir/disk.mnt
mkdir -- "$mount_dir"
mount -- "$root_dev" "$mount_dir"

echo '- Installing Arch Linux.'
append_gce_repo() {
	gawk -i inplace '
		/^\[gce\]$/ { found = 1 } { print }
		ENDFILE { if (!found) {
			print ""
			print "[gce]"
			print "Server = https://storage.googleapis.com/arch-linux-gce/repo"
			print "SigLevel = Optional TrustAll"
		} }' "$1"
}
cp /etc/pacman.conf "$work_dir"
append_gce_repo "$work_dir/pacman.conf"
pacstrap -G -M -C "$work_dir/pacman.conf" -- "$mount_dir" \
	base linux grub e2fsprogs dhclient openssh sudo google-compute-engine growpartfs
append_gce_repo "$mount_dir/etc/pacman.conf"

echo '- Configuring fstab.'
root_uuid=$(lsblk --noheadings --raw --output UUID -- "$root_dev")
{
	printf '# LABEL=%s\n' root
	printf 'UUID=%-20s' "$root_uuid"
	printf '\t%-10s' / ext4 defaults
	printf '\t%s %s' 0 1
	printf '\n\n'
} >> "$mount_dir/etc/fstab"

echo '- Running additional setup in chroot.'
arch-chroot -- "$mount_dir" /bin/bash -s -- "$loop_dev" <<-'EOS'
	set -eEuo pipefail
	trap 'echo "Error: \`$BASH_COMMAND\` exited with status $?"' ERR
	echo '-- Configuring time.'
	ln -sf /usr/share/zoneinfo/UTC /etc/localtime
	gawk -i assert -i inplace '
		/^#NTP=/ { $0 = "NTP=metadata.google.internal"; ++f }
		{ print } END { assert(f == 1, "f == 1") }' /etc/systemd/timesyncd.conf
	systemctl --quiet enable systemd-timesyncd.service
	echo '-- Configuring locale.'
	gawk -i assert -i inplace '
		/^#en_US\.UTF-8 UTF-8\s*$/ { $0 = substr($0, 2); ++f }
		{ print } END { assert(f == 1, "f == 1") }' /etc/locale.gen
	locale-gen
	echo 'LANG=en_US.UTF-8' > /etc/locale.conf
	echo '-- Configuring journald.'
	gawk -i assert -i inplace '
		/^#ForwardToConsole=/ { $0 = "ForwardToConsole=yes"; ++f }
		{ print } END { assert(f == 1, "f == 1") }' /etc/systemd/journald.conf
	echo '-- Configuring ssh.'
	gawk -i assert -i inplace '
		/^#PasswordAuthentication / { $0 = "PasswordAuthentication no"; ++f1 }
		/^#PermitRootLogin / { $0 = "PermitRootLogin no"; ++f2 }
		{ print } END { assert(f1 * f2 == 1, "f == 1") }' /etc/ssh/sshd_config
	systemctl --quiet enable sshd.service
	echo '-- Configuring pacman.'
	curl --silent --show-error -o /etc/pacman.d/mirrorlist \
		'https://archlinux.org/mirrorlist/?country=all&ip_version=4&use_mirror_status=on'
	gawk -i assert -i inplace '
		/^#Server / { $0 = substr($0, 2); ++f }
		{ print } END { assert(f > 0, "f > 0") }' /etc/pacman.d/mirrorlist
	cat <<-'EOF' > /etc/systemd/system/pacman-init.service
		[Unit]
		Description=Pacman keyring initialization
		ConditionDirectoryNotEmpty=!/etc/pacman.d/gnupg
		[Service]
		Type=oneshot
		RemainAfterExit=yes
		ExecStart=/usr/bin/pacman-key --init
		ExecStart=/usr/bin/pacman-key --populate archlinux
		[Install]
		WantedBy=multi-user.target
	EOF
	systemctl --quiet enable pacman-init.service
	echo '-- Enabling other services.'
	systemctl --quiet enable dhclient@eth0.service growpartfs@-.service
	echo '-- Configuring initcpio.'
	gawk -i assert -i inplace '
		/^MODULES=/ { $0 = "MODULES=(virtio_pci virtio_scsi sd_mod ext4)"; ++f1 }
		/^BINARIES=/ { $0 = "BINARIES=(fsck fsck.ext4)"; ++f2 }
		/^HOOKS=/ { $0 = "HOOKS=(base modconf)"; ++f3 }
		{ print } END { assert(f1 * f2 * f3 == 1, "f == 1") }' /etc/mkinitcpio.conf
	gawk -i assert -i inplace '
		/^PRESETS=/ { $0 = "PRESETS=(default)"; ++f }
		/#?fallback_/ { next }
		{ print } END { assert(f == 1, "f == 1") }' /etc/mkinitcpio.d/linux.preset
	rm /boot/initramfs-linux-fallback.img
	mkinitcpio --nocolor --preset linux
	echo '-- Configuring grub.'
	grub-install --target=i386-pc -- "$1"
	cat <<-'EOF' > /etc/default/grub
		# GRUB boot loader configuration
		GRUB_CMDLINE_LINUX="console=ttyS0,38400n8 net.ifnames=0 elevator=noop scsi_mod.use_blk_mq=Y"
		GRUB_PRELOAD_MODULES="part_gpt part_msdos"
		GRUB_TIMEOUT=0
		GRUB_DISABLE_RECOVERY=true
	EOF
	grub-mkconfig -o /boot/grub/grub.cfg
EOS

echo '- Cleaning up and finalizing the image.'
> "$mount_dir/etc/machine-id"
rm -- "$mount_dir/var/log/pacman.log"
rm -f "$mount_dir/var/cache/pacman/pkg/*"
umount -- "$mount_dir"
unset mount_dir

echo '- Building the compressed image.'
disk_tar="arch-v$(date --utc +%Y%m%d).tar.gz"
tar --sparse -czf "$work_dir/$disk_tar" --directory="$work_dir" disk.raw
mv -- "$work_dir/$disk_tar" .

echo "Successfully built image \`$disk_tar\`."