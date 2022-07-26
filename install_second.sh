#!/usr/bin/env -S zsh -s

# Time, Bootloader and Networking/SSH, change partitions for Sata/NVME

# vars
source  /root/install_vars.txt

# install_drive=$1
echo "install_drive is $install_drive"
# drive_name=$2
echo "drive name is $drive_name"
# drive_path=$3
echo "drive path is $drive_path"
# hostname=$4
echo "hostname is $hostname"
# eth_name=$5
echo "ethernet adapter is $eth_name"
# wifi_name=$6
echo "wifi adapter is $wifi_name"
# wifi_pass=$7
echo "wifi password is ____"

# get CPU manufacturer (my desktop is AMD and laptop is intel)
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ "$CPU" == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
    echo "..AMD CPU chosen, loading Virtualbox modules"
    pacman -S --noconfirm virtualbox-guest-utils 
    systemctl enable vboxservice
else
    microcode="intel-ucode"
    echo "..Intel CPU chosen"
fi

# set hostname
echo "..setting hostname"
echo $hostname >> /etc/hostname

# change /etc/locale.gen and remove #
echo "..setting location"
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
# localectl set-locale LANG=en_US.UTF-8
locale-gen

# sync clock
echo "..setting system clock"
hwclock --systohc

# TTY font
setfont Tamsyn10x20r
echo "FONT=Tamsyn10x20r" > /etc/vconsole.conf

# install systemd boot
bootctl --path=/boot install

# change /etc/mkinitcpio.conf HOOKS to include btrfs, resume is for hybernation.
echo "..setting system hooks"
all_hooks="base systemd keyboard autodetect modconf block sd-vconsole sd-encrypt filesystems fsck"
sed -i "s/^HOOKS=.*/HOOKS=(${all_hooks})/" /etc/mkinitcpio.conf
sed -i "s/^MODULES=().*/MODULES=(btrfs)/" /etc/mkinitcpio.conf
sed -i "s/^BINARIES=().*/BINARIES=(/usr/bin/btrfs)/" /etc/mkinitcpio.conf

echo "..writing EFI preset"
cat > /etc/mkinitcpio.d/linux.preset << EOL
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
ALL_microcode=(/boot/$microcode.img)

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_efi_image="/boot/EFI/arch.efi"
EOL

# find offset for swap and hibernation
echo "..finding swap offset"
cd /tmp
curl -s "https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c" > bmp.c
gcc -O2 -o bmp bmp.c
swp_offset=$(echo "$(./bmp /swap/swapfile | egrep "^0\s+" | cut -f9) / $(getconf PAGESIZE)" | bc)
cd /

# hybernation (needed)?
# echo $swp_offset > /sys/power/resume_offset


# find encrypted drives UUID
cryptuuid=$(cryptsetup luksUUID "$install_drive"p2)

# kernal hooks
echo "..writing kernal hook to cmdline"
cat > /etc/kernel/cmdline << EOL
rd.luks.name=$cryptuuid=$drive_name rootflags=subvol=root root=$drive_path resume=$drive_path resume_offset=$swp_offset rw
EOL

# refresh hooks
mkinitcpio -P 

# build EFI
echo "..updating EFI"
efibootmgr --create --disk "$install_drive"p2 --label "ArchLinux" --part 1 --loader '\EFI\arch.efi' --verbose 


# NETWORKING:
# install ssh
echo "..setting ssh"

# generate ssh keys
ssh-keygen -A

# start ssh service
systemctl enable --now sshd

# point to keys (disable root login after setup)
cat > /etc/ssh/sshd_config <<EOL
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin yes
EOL

# make hostfile
echo "..making hostfile"
cat > /etc/hosts <<EOL
127.0.1.1 $hostname.localdomain $hostname
::1 localhost 
127.0.0.1	localhost
EOL

# enable network, change wifi name and password 
echo -e "[Match]\nName=$eth_name\n[Network]\nDHCP=yes" > /etc/systemd/network/20-wired.network
echo -e "[Match]\nName=wlan0\n[Network]\nDHCP=yes" > /etc/systemd/network/25-wireless.network
systemctl enable systemd-networkd systemd-resolved iwd 
echo -e "station wlan0 connect $wifi_name \n$wifi_pass \nexit" iwctl 

# ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf  

# tune network dropout time
mkdir /etc/systemd/system/systemd-networkd-wait-online.service.d
cat > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any -timeout=30
EOL

