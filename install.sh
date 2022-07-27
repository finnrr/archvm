#!/usr/bin/env -S zsh -s
# Arch initial setup with UEFI, LUKS, BTRFS, Swap, BTRFS with subvolumes and snapshot
# todo: add systemd-boot and TMP2 to hold LUKS key
# run with following command, warning will wipe drive/data:
# ssh -p 2266 root@localhost
# zsh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install.sh)"
# drive partition numbers are hardcoded in script

# set root password
# passwd

# clear console
clear

# make font big
# setfont latarcyrheb-sun32
# or
# pacman -S terminus-font
# setfont ter-v32b

# check internet
# ping 8.8.8.8 -c 1
# ip -c a

# predefine vars
install_drive=/dev/sda
drive_name=drive1
swap_size=8196

# ask for vars if they dont exist
if [ -z "$install_drive" ]; then
    lsblk
    vared -p "%F{blue}drive name?: %f" -c installdrive
    installdrive=/dev/$install_drive
fi

if [ -z "$drive_name" ]; then
    vared -p "%F{blue}data partition name?: %f" -c drive_name
fi

if [ -z "$drive_pass" ]; then
    vared -p "%F{red}drive password?: %f" -c drive_pass
fi

if [ -z "$swap_size" ]; then
    vared -p "%F{blue}swap size (in MB)?: %f" -c swap_size
fi

# update keyring and mirrors
# echo Updating Keyring and Mirrors
# pacman -Syy --noconfirm archlinux-keyring reflector
# reflector --age 12 --latest 10 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
# get UTC time
echo Getting Time
timedatectl set-ntp true

# partition 512MB boot / rest, you'll need more for multiboot or encryption
echo Wiping Data From $install_drive
cryptsetup erase $install_drive
wipefs -a $install_drive
sgdisk --zap-all $install_drive


# badblocks -c 10240 -s -w -t random -v $install_drive
echo Partitioning $install_drive
sgdisk -n 0:0:+256MiB -a 4096 -t 0:ef00 -c 0:efi $install_drive

# for no encryption:
# sgdisk -n 0:0:0 -t 0:8300 -c 0:root $installdrive

# make sure rest of drive is in 4096 sized blocks for encryption
end_position=$(sgdisk -E $install_drive)
sgdisk -a 4096 -n2:0:$(( $end_position - ($end_position + 1) % 4096 )) -t 0:8309 -c 0:root $install_drive 

# set up encrypted drive 
echo -n ${drive_pass} | cryptsetup luksFormat -q --iter-time 500 --key-size 256 --sector-size 4096 --type luks2 "$install_drive"2 -d -

# open encrypted drive
echo Open LUKS partition
echo -n ${drive_pass} |cryptsetup open "$install_drive"2 $drive_name
drive_path=/dev/mapper/$drive_name

# remove password from env
unset drive_pass

# format 
echo Formating File System
mkfs.vfat -F32 -n EFI "$install_drive"1
mkfs.btrfs --force -L ROOT $drive_path -f

# mount and make subvolumes to /mnt
echo Mounting Drives and Making Subvolumes
mount $drive_path /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/tmp
btrfs subvolume create /mnt/log
btrfs subvolume create /mnt/pkg
btrfs subvolume create /mnt/swap
btrfs subvolume create /mnt/snaps
# btrfs subvolume list /mnt
umount -R /mnt

# remount with variables
echo Mounting Subvolumes and Boot
mount_vars="noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol="
mount -o "$mount_vars"root $drive_path /mnt
mkdir -p /mnt/{boot/efi,home,swap,/var/tmp,/var/log,/var/cache/pacman/pkg,.snapshots}
mount -o "$mount_vars"home $drive_path /mnt/home
mount -o "$mount_vars"tmp $drive_path /mnt/var/tmp
mount -o "$mount_vars"log $drive_path /mnt/var/log
mount -o "$mount_vars"pkg $drive_path /mnt/var/cache/pacman/pkg/
mount -o "$mount_vars"snaps $drive_path /mnt/.snapshots
mount -o "$mount_vars"swap $drive_path /mnt/swap
mount "$install_drive"1 /mnt/boot/efi

# disable CoW
echo turning off CoW 
chattr +C /mnt/var/cache/pacman/pkg/
chattr +C /mnt/var/log
chattr +C /mnt/var/tmp
chattr +C /mnt/swap

# make swap
echo Making Swap
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=$swap_size status=progress
chmod 0600 /mnt/swap/swapfile
btrfs property set /mnt/swap/swapfile compression none #maybe redundant
mkswap -U clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# commands to check stuff
# btrfs subvolume list -p -t /mnt
# findmnt -nt btrfs
# lsblk
# fdisk -l 

# now install linux
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install_second.sh)"