# install linux (replace packages as needed, ie. intel for amd)
pacstrap /mnt base btrfs-progs linux linux-firmware intel-ucode neovim iwd base-devel bc 

# enter installation
arch-chroot /mnt

# create boot EFI (previous entries may have to be deleted)
bootctl --path=/boot install

# find offset for swap and hibernation
cd /tmp
curl -s "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" > bmp.c
gcc -O2 -o bmp bmp.c
swp_offset=$(echo "$(./bmp /swap/swapfile | egrep "^0\s+" | cut -f9) / $(getconf PAGESIZE)" | bc) && echo $swp_offset
# change: /boot/loader/entries/arch.conf
echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /intel-ucode.img\ninitrd /initramfs-linux.img\noptions root=/dev/sda2 rootflags=subvol=root rw resume=/dev/sda2" >> /boot/loader/entries/arch.conf
echo -e "resume=/dev/sda2+=\" resume_offset=$swp_offset \"" | tee -a /boot/loader/entries/arch.conf

#change /boot/loader/loader.conf
rm /boot/loader/loader.conf
echo -e 'default  arch.conf\ntimeout  4\nconsole-mode max\neditor   no' >> /boot/loader/loader.conf

# default  arch.conf
# timeout  4
# console-mode max
# editor   no

#change /etc/mkinitcpio.conf HOOKS to include btrfs, resume is for hybernation.
sed -i 's/HOOKS=(/HOOKS=(btrfs resume /' /etc/mkinitcpio.conf
mkinitcpio -p linux

# add time (timedatectl list-timezones)
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime

#sync clock
hwclock --systohc

# change /etc/locale.gen and remove #
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
localectl set-locale LANG=en_US.UTF-8
locale-gen

#set hostname
echo reactor7 >> /etc/hostname

#make hostfile
echo -e '127.0.1.1 reactor7.localdomain reactor7 \n::1 localhost \n127.0.0.1	localhost' >> /etc/hosts 

#enable network, change wifi name and password 
echo -e '[Match]\nName=enp0s31f6\n[Network]\nDHCP=yes' /etc/systemd/network/20-wired.network
echo -e '[Match]\nName=wlan0\n[Network]\nDHCP=yes' /etc/systemd/network/25-wireless.network
systemctl enable --now systemd-networkd systemd-resolved iwd
echo -e 'station wlan0 connect <WIFINAME>\<WIFIPASSWORD>\nexit' iwctl 
systemctl restart systemd-networkd

#install stuff
pacman --noconfirm -Syu python python-pip sudo git  firefox discord bluez bluez-utils foot wget hwdetect sway wayland xf86-input-synaptics

#remove install files
pacman -Scc

#remove orphans
pacman -Qtdq | pacman -Rns -

#enable bluetooth
echo AutoEnable=true >> /etc/bluetooth/main.conf
systemctl enable bluetooth.service

#sway 
systemctl enable seatd.service 

#add users and set root password
passwd root
useradd -m -G wheel,seat -s /usr/bin/zsh bob
passwd bob
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

