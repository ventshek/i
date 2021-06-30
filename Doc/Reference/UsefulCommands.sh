Write iso = 'dd bs=4M if=/home/user/Downloads/archlinux-2021.06.01-x86_64.iso of=/dev/sdc conv=fsync oflag=direct status=progress'
Change password = 'echo username:password | chpasswd'
Create user = 'useradd -m -d /home/user -G wheel -s /bin/bash your_username'
Generate SSH keys = 'ssh-keygen'
List groups = 'cat /etc/group'
Xrdp = 'systemctl enable xrdp.service xrdp-sesman.service'
Network fix = '/sbin/dhcpcd -B -K -L -G -c /usr/lib/networkmanager/nm-dhcp-client.action wlan0'
Archfi install = 'curl -LO matmoul.github.io/archfi'
Print specific UUID = 'blkid -o value -s UUID /dev/sdXx'
Show disk useage = 'fd -h'
Vmware as guest = 'pacman -S open-vm-tools xf86-video-vmware xf86-input-vmmouse sudo systemctl enable vmtoolsd vmware-vmblock-fuse'
Check for rootkits = 'sudo rkhunter --check'
KDE dir = '/usr/share/kde4/apps/desktoptheme/'
Import ova = 'vboxmanage import test.ova'
Supress output = '> /dev/nul'
Supress output and errors = '&> /dev/nul'
wget images = 'wget -nd -r -P /save/location -A jpeg,jpg,bmp,gif,png http://www.somedomain.com'


Writing scripts, maybe =
{
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
}

EFI Sign keys = ? 
{

}


