#!/usr/bin/env -S zsh -s
# vars
install_drive=/dev/sda
drive_name=drive1
drive_path=/dev/mapper/$drive_name
hostname=ComputerX
User_Name=Bob



# set hostname
echo "setting hostname"
echo $hostname >> /etc/hostname

# make hostfile
echo "making hostfile"
cat > /etc/hosts <<EOL
127.0.1.1 $hostname.localdomain $hostname
::1 localhost 
127.0.0.1	localhost
EOL

# change /etc/locale.gen and remove #
echo "setting location"
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
localectl set-locale LANG=en_US.UTF-8
locale-gen

# add time (timedatectl list-timezones)
echo "setting time"
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime

# sync clock
hwclock --systohc

# change /etc/mkinitcpio.conf HOOKS to include btrfs, resume is for hybernation.
echo "setting system hooks"
all_hooks="base udev block keyboard encrypt filesystems"
sed -i "s/^HOOKS=.*/HOOKS=(${all_hooks})/" /etc/mkinitcpio.conf
# base systemd autodetect keyboard  modconf block sd-encrypt filesystems resume fsck
mkinitcpio -p linux
# create boot EFI (previous entries may have to be deleted)
echo "generating boot efi"
bootctl --path=/boot/efi install

# find offset for swap and hibernation
cd /tmp
curl -s "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" > bmp.c
gcc -O2 -o bmp bmp.c
swp_offset=$(echo "$(./bmp /swap/swapfile | egrep "^0\s+" | cut -f9) / $(getconf PAGESIZE)" | bc)
cd /

# find encrypted drives UUID
cryptuuid=$(cryptsetup luksUUID "$install_drive"2)
# echo "$drive_name UUID=$cryptuuid" >> /etc/crypttab.initramfs

# get CPU manufacturer
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ "$CPU" == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
    echo "AMD CPU chosen"
else
    microcode="intel-ucode"
    echo "Intel CPU chosen"
fi

# create kernal hooks
echo "setting kernal hooks"
cat > /boot/efi/loader/entries/arch.conf << EOL
title Arch Linux
linux /vmlinuz-linux
initrd /$microcode.img
initrd /initramfs-linux.img
options cryptdevice=UUID=$cryptuuid:$drive_name root=$drive_path rootflags=subvol=root rw resume=$drive_path resume_offset=$swp_offset
EOL

# change /boot/loader/loader.conf
# rm /boot/efi/loader/loader.conf
cat > /boot/efi/loader/loader.conf << EOL
default  arch.conf
timeout  4
console-mode max
editor   no
EOL

# exit
# umount -R -l /mnt
# reboot










    
			

			




