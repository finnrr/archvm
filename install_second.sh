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
    echo "AMD CPU chosen, loading Virtualbox modules"
    pacman -S virtualbox-guest-utils
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
mkinitcpio -P

bootctl --esp-path=/efi install

cat > /efi/loader/loader.conf <<EOF
default arch.conf
timeout 3
console-mode max
editor yes
EOF

# mkdir -p /efi/EFI/Arch

# # ALL_microcode=(/boot/$microcode.img)
# cat > /etc/mkinitcpio.d/linux.preset << EOL
# ALL_config="/etc/mkinitcpio.conf"
# ALL_kver="/boot/vmlinuz-linux"

# PRESETS=('default')

# default_image="/boot/initramfs-linux.img"
# default_efi_image="/efi/EFI/Arch/linux.efi"
# EOL

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

cat > /efi/loader/entries/arch.conf << EOL
title Arch
linux /vmlinuz-linux
initrd /intel-ucode.img (or /amd-ucode.img for AMD CPU)
initrd /initramfs-linux.img
rd.luks.name=$cryptuuid=$drive_name rootflags=subvol=root root=$drive_path resume=$drive_path resume_offset=$swp_offset rw bgrt_disable
EOL

# regen
mkinitcpio -P 

echo "updating EFI"

# efibootmgr --create --disk "$install_drive"2 --label "ArchLinux" --loader '\EFI\Arch\linux.efi' --verbose

# efibootmgr --create --disk "$install_drive"2 --label "ArchLinux-fallback" --loader '\EFI\Arch\linux-fallback.efi' --verbose

# system should now be bootable, but to connect add ssh:

# install ssh
pacman -S openssh

# generate ssh keys
ssh-keygen -A

# point to keys
cat > /etc/ssh/sshd_config <<EOL
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
EOL

# start ssh server
systemctl enable --now sshd

# UEFI Keys

# generate keys 
pacman -S efitools sbsigntools

# gen random key
cd /root
uuidgen --random > GUID.txt

# platform key
openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 36500 -subj "/CN=my Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth

# sign empty file
sign-efi-sig-list -g "$(< GUID.txt)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

# key exchange key
openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 36500 -subj "/CN=my Key Exchange Key/" -out KEK.crt
openssl x509 -outform DER -in KEK.crt -out KEK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

# Signature Database key
openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 36500 -subj "/CN=my Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k KEK.key -c KEK.crt db db.esl db.auth

cp /root/*.{cer,esl,auth} /efi/

# autosign EFI using pacman

mkdir /etc/pacman.d/hooks

cat > /etc/pacman.d/hooks/99-secureboot.hook <<EOL
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOL

# cat > /etc/pacman.d/hooks/99-secureboot.hook <<EOL
# [Trigger]
# Operation = Install
# Operation = Upgrade
# Type = Path
# Target = usr/lib/modules/*/vmlinuz
# Target = usr/lib/initcpio/*
# [Action]
# Description = Signing EFI executables for SecureBoot...
# When = PostTransaction
# Exec = /usr/bin/find /efi/EFI/Arch -type f ( -name *.efi ) \
# -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null \
# | /usr/bin/grep -q "signature certificates"; then /usr/bin/sbsign \
# --key /root/db.key --cert /root/db.crt -- output "\$1" "\$1"; fi' _ {} ;
# Depends = sbsigntools
# Depends = findutils
# Depends = grep
# EOL


# secure boot
# copy keys
# cp /root/*.{cer,esl,auth} /efi/
# 3.14.4.2 Boot into UEFI firmware setup utility & Go to Secure Boot options
# systemctl reboot --firmware
# OR by hitting the [F2] or [Del] key at boot.
# > Activate vendor specific settings like "Expert Key Management".
# 3.14.4.3 Backup & Delete preloaded Secure Boot keys
# > Save your Secure Boot keys! (ALT)
# > Delete all preloaded Secure Boot keys: ALL or db -> KEK -> PK
# (Secure Boot is now in "Setup Mode")
# 3.14.4.4 Enroll db, KEK and PK certificates
# > Set or append the new keys: db -> KEK -> PK
# (Secure Boot is now in "User Mode")
# Note: If supported use .auth and .esl over .cer.
# 3.14.5 Set UEFI supervisor (administrator) password
# ... to protect the firmware settings.
# 3.14.6 Reboot & Verify Secure Boot status
# od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot*
# > Output e.g.: 6 0 0 0 1 (1 as the final integer)



exit


