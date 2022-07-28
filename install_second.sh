#!/usr/bin/env -S zsh -s
# vars
install_drive=/dev/sda
drive_name=drive1
drive_path=/dev/mapper/$drive_name
hostname=reactor7
User_Name=wrk

# get CPU manufacturer
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ "$CPU" == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
    echo "AMD CPU chosen"
else
    microcode="intel-ucode"
    echo "Intel CPU chosen"
fi

# set root password
passwd

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
all_hooks="base systemd keyboard autodetect modconf block sd-encrypt filesystems fsck"
sed -i "s/^HOOKS=.*/HOOKS=(${all_hooks})/" /etc/mkinitcpio.conf
sed -i "s/^BINARIES=().*/BINARIES=(btrfs)/" /etc/mkinitcpio.conf
# base systemd autodetect keyboard  modconf block sd-encrypt filesystems resume fsck
mkinitcpio -Pv

mkdir -p /efi/EFI/Arch

# ALL_microcode=(/boot/$microcode.img)
cat > /etc/mkinitcpio.d/linux.preset << EOL
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_efi_image="/efi/EFI/Arch/linux.efi"
EOL

# find offset for swap and hibernation
cd /tmp
curl -s "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" > bmp.c
gcc -O2 -o bmp bmp.c
swp_offset=$(echo "$(./bmp /swap/swapfile | egrep "^0\s+" | cut -f9) / $(getconf PAGESIZE)" | bc)
cd /

# find encrypted drives UUID
cryptuuid=$(cryptsetup luksUUID "$install_drive"2)

cat > /etc/kernel/cmdline << EOL
rd.luks.name=$cryptuuid=$drive_name rootflags=subvol=root root=$drive_path resume=$drive_path resume_offset=$swp_offset rw bgrt_disable
EOL

# regen
mkinitcpio -P 

echo "updating EFI"
efibootmgr --create --disk "$install_drive"2 --label "ArchLinux" --loader '\EFI\Arch\linux.efi' --verbose

# efibootmgr --create --disk "$install_drive"2 --label "ArchLinux-fallback" --loader '\EFI\Arch\linux-fallback.efi' --verbose

exit
