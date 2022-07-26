#!/usr/bin/env zsh
# vars
install_drive=/dev/sda
drive_name=drive1
drive_path=/dev/mapper/$drive_name
hostname=ComputerX
User_Name=Bob

# install linux (replace packages as needed, ie. intel for amd)
pacstrap /mnt base btrfs-progs linux linux-firmware intel-ucode neovim iwd base-devel bc zsh gcc

# pacstrap /mnt base btrfs-progs linux linux-firmware amd-ucode neovim iwd base-devel bc zsh gcc

# generate fstab (confirm /etc/fstab swap looks like: /swap/swapfile none swap defaults 0 0)
# genfstab -L -p /mnt >> /mnt/etc/fstab

# enter installation
arch-chroot /mnt

# create boot EFI (previous entries may have to be deleted)
bootctl --path=/boot install

cryptuuid=$(cryptsetup luksUUID "$install_drive"2)
echo $cryptuuid
# change: options root=/dev/sda2 rootflags=subvol=root rw resume=/dev/sda2
cat > /boot/loader/entries/arch.conf << EOL
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options cryptdevice=UUID="$cryptuuid":root root=$drive_path rootflags=subvol=root rw resume=$drive_path
EOL

# find offset for swap and hibernation
cd /tmp
curl -s "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" > bmp.c
gcc -O2 -o bmp bmp.c
swp_offset=$(echo "$(./bmp /swap/swapfile | egrep "^0\s+" | cut -f9) / $(getconf PAGESIZE)" | bc) && echo $swp_offset
sed -i  "s#resume=${drive_path}# resume_offset=${swp_offset}#g" /boot/loader/entries/arch.conf
cd /

# lower swap
sysctl vm.swappiness=10

# change /boot/loader/loader.conf
rm /boot/loader/loader.conf
cat > /boot/loader/loader.conf << EOL
default  arch.conf
timeout  4
console-mode max
editor   no
EOL

# change /etc/mkinitcpio.conf HOOKS to include btrfs, resume is for hybernation.
sed -i 's/HOOKS=(/HOOKS=(encrypt btrfs resume /' /etc/mkinitcpio.conf
mkinitcpio -p linux

# add time (timedatectl list-timezones)
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime

# sync clock
hwclock --systohc

# change /etc/locale.gen and remove #
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
localectl set-locale LANG=en_US.UTF-8
locale-gen

# set hostname
echo $hostname >> /etc/hostname

# make hostfile
echo -e '127.0.1.1 reactor7.localdomain reactor7 \n::1 localhost \n127.0.0.1	localhost' >> /etc/hosts 

# enable network, change wifi name and password 
echo -e '[Match]\nName=enp0s31f6\n[Network]\nDHCP=yes' /etc/systemd/network/20-wired.network
echo -e '[Match]\nName=wlan0\n[Network]\nDHCP=yes' /etc/systemd/network/25-wireless.network
systemctl enable --now systemd-networkd systemd-resolved iwd
echo -e 'station wlan0 connect <WIFINAME> \n<WIFIPASSWORD> \nexit' iwctl 
systemctl restart systemd-networkd

# tune network dropout time
mkdir /etc/systemd/system/systemd-networkd-wait-online.service.d
cat > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any -timeout=30
EOL

#set global vars in /etc/environment
cat > /etc/environment << EOL
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
EDITOR=nvim
VISUAL=nvim
XDG_CURRENT_DESKTOP=sway
EOL

#set vars in profile
echo ZDOTDIR=$HOME/.config/zsh >> /etc/zsh/zshenv
echo export XDG_CONFIG_HOME="$HOME/.config" >> /etc/profile 
echo export XDG_CACHE_HOME="$HOME/.cache" >> /etc/profile
echo export XDG_DATA_HOME="$HOME/.local/share" >> /etc/profile
echo export XDG_STATE_HOME="$HOME/.local/state" >> /etc/profile

#update keyring
pacman -S archlinux-keyring reflector 
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu

# install drivers
pacman --noconfirm -Syu bluez bluez-utils xf86-input-synaptics

# install sway desktop
pacman -S sway wayland foot

# sound pipewire-alsa pipewire-pulse 
pacman -S pipewire wireplumber 

# utils and programming
pacman -S python python-pip git wget hwdetect 

# software
pacman -S firefox discord 

# remove install files
pacman -Scc

# remove orphans
pacman -Qtdq | pacman -Rns -

# enable bluetooth
echo AutoEnable=true >> /etc/bluetooth/main.conf
systemctl enable bluetooth.service

# sway 
systemctl enable seatd.service 

# add users and set root password
echo Set Root Password
passwd root
echo "Set Password for $User_Name"
useradd -m -G wheel,seat -s /usr/bin/zsh $User_Name
passwd $User_Name
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


exit
umount -R -l /mnt
reboot

# login as user and:
# /opt/git clone https://aur.archlinux.org/yay.git
# makepkg -si







# for thinkpad, max brightness brightness
echo 852 > /sys/class/backlight/intel_backlight/brightness

# for thinkpad, get brightness function keys working
sed '/^CHANGETHIS$/r'<(cat <<EOF
video/brightnessup)
            case "$2" in
                    BRTUP)
                        logger 'BrightnessUp button pressed'
                        echo $((`cat /sys/class/backlight/intel_backlight/brightness` + 106)) > /sys/class/backlight/intel_backlight/brightness
                        ;;
                    *)
                        logger "ACPI action undefined: $2"
                        ;;
            esac
            ;;

    video/brightnessdown)
            case "$2" in
                    BRTDN)
                        logger 'BrightnessDown button pressed'
                        echo $((`cat /sys/class/backlight/intel_backlight/brightness` - 106)) > /sys/class/backlight/intel_backlight/brightness
                        ;;
                    *)
                        logger "ACPI action undefined: $2"
                        ;;
            esac
            ;;
EOF
) -i -- /etc/acpi/handler.sh
    
			

			



# systemctl enable systemd-homed
# systemctl enable systemd-timesyncd
