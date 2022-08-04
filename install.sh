#!/usr/bin/env -S zsh -s
# Arch initial setup with UEFI, LUKS, Swap, BTRFS with subvolumes and snapshot
# todo: add systemd-boot(not possible without efifs driver?),TMP2 to hold LUKS key (do that in other script)

# first on machine set root password with 'passwd' then ssh in:
# ssh -p 2266 root@localhost
# run with following command, warning will wipe drive/data:
# zsh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install.sh)"
# drive partition numbers are hardcoded in script, this is for single drive.

# commands to check stuff
# btrfs subvolume list -p -t /mnt
# findmnt -nt btrfs
# lsblk
# fdisk -l 

# clear console
clear

# predefine vars
set -a
install_drive=/dev/sda
drive_name=drive1
drive_path=/dev/mapper/$drive_name
swap_size=8196
user_name=wrk
hostname=reactor7
eth_name=enp0s31f6 
# enp0s3
wifi_name=Bell187
my_location=America/Toronto
# my_location="$(curl -s http://ip-api.com/line?fields=timezone)"

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

if [ -z "$user_name" ]; then
    vared -p "%F{blue}user name??: %f" -c user_name
fi

if [ -z "$user_pass" ]; then
    vared -p "%F{blue}user password?: %f" -c user_pass
fi

if [ -z "$root_pass" ]; then
    vared -p "%F{blue}root password?: %f" -c root_pass
fi

if [ -z "$wifi_pass" ]; then
    vared -p "%F{blue}wifi password?: %f" -c wifi_pass
fi

# make font big
# setfont latarcyrheb-sun32
# or
# pacman -S terminus-font
# setfont ter-v32b
pacman -Syy --noconfirm tamsyn-font
setfont Tamsyn10x20r
# check internet
# ping 8.8.8.8 -c 1
# ip -c a

# update keyring and mirrors
echo "..Updating Keyring and Mirrors"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf
pacman -Syy --noconfirm archlinux-keyring reflector
reflector --age 12 --latest 10 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
# get UTC time
echo "..Getting Time"
timedatectl set-ntp true

# partition 512MB boot / rest, you'll need more for multiboot or encryption
echo "..Wiping Data From $install_drive"
cryptsetup erase $install_drive
wipefs -a $install_drive
sgdisk --zap-all $install_drive

# badblocks -c 10240 -s -w -t random -v $install_drive
echo "..Partitioning $install_drive"
sgdisk -n 0:0:+256MiB -a 4096 -t 0:ef00 -c 0:efi $install_drive

# for no encryption:
# sgdisk -n 0:0:0 -t 0:8300 -c 0:root $installdrive

# make sure rest of drive is in 4096 sized blocks for encryption
end_position=$(sgdisk -E $install_drive)
sgdisk -a 4096 -n 2:257M:$(( $end_position - ($end_position + 1) % 4096 )) -t 0:8309 $install_drive 

# set up encrypted drive 
echo -n ${drive_pass} | cryptsetup luksFormat -q --iter-time 500 --key-size 256 --sector-size 4096 --align-payload 2048 --type luks2 "$install_drive"2 -d -

# open encrypted drive
echo "..Open LUKS partition"
echo -n ${drive_pass} |cryptsetup open "$install_drive"2 $drive_name
drive_path=/dev/mapper/$drive_name

# remove password from env (better to set manually)
unset drive_pass

# format file system
echo "..Formating File System"
mkfs.vfat -F32 -n EFI "$install_drive"1
mkfs.btrfs --force -L ROOT $drive_path -f

# mount and make subvolumes to /mnt
echo "..Making Subvolumes"
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
echo "..Mounting Subvolumes and Boot"
mount_vars="noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol="
mount -o "$mount_vars"root $drive_path /mnt
mkdir -p /mnt/{boot,home,swap,/var/tmp,/var/log,/var/cache/pacman/pkg,.snapshots}
mount -o "$mount_vars"home $drive_path /mnt/home
mount -o "$mount_vars"tmp $drive_path /mnt/var/tmp
mount -o "$mount_vars"log $drive_path /mnt/var/log
mount -o "$mount_vars"pkg $drive_path /mnt/var/cache/pacman/pkg/
mount -o "$mount_vars"snaps $drive_path /mnt/.snapshots
mount -o "$mount_vars"swap $drive_path /mnt/swap
mount "$install_drive"1 /mnt/boot

# disable CoW
echo "..turning off CoW" 
chattr +C /mnt/var/cache/pacman/pkg/
chattr +C /mnt/var/log
chattr +C /mnt/var/tmp
chattr +C /mnt/swap

# make swap
echo "..Making Swap"
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=$swap_size status=progress
chmod 0600 /mnt/swap/swapfile
mkswap -U clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# get CPU manufacturer
CPU=$(grep vendor_id /proc/cpuinfo)
if [[ "$CPU" == *"AuthenticAMD"* ]]; then
    microcode="amd-ucode"
    echo "AMD CPU chosen"
else
    microcode="intel-ucode"
    echo "Intel CPU chosen"
fi

# install linux, neovim for editor, iwd for wifi, zsh for shell, bc to calculate swap offset
echo "installing linux"
linux_packages="base linux linux-firmware"
build_packages="base-devel efitools sbsigntools efibootmgr bc"
system_packages="btrfs-progs $microcode sof-firmware libva-intel-driver intel-media-driver vulkan-intel"
software_packages="neovim zsh zsh-completions openssh iwd"
pacstrap /mnt $(echo $linux_packages $build_packages $system_packages $software_packages)

# generate fstab (confirm /etc/fstab swap looks like: /swap/swapfile none swap defaults 0 0)
echo "making fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# add time (timedatectl list-timezones)
echo "setting time"
arch-chroot  /mnt ln -sf /usr/share/zoneinfo/$my_location /etc/localtime

#set root password
echo "root:$root_pass" | arch-chroot /mnt chpasswd 

# now part 2 for system setup 
export > /mnt/root/install_vars.txt
echo "..running second script: location, bootloader and networking."
# vars="$_ $install_drive $drive_name $drive_path $hostname $eth_name $wifi_name $wifi_pass"
arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install_second.sh)" # $vars

# now user and drivers and some software
# echo "..running third script: drivers, settings, users and software"
# vars="$_ $user_name $user_pass"
arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install_third.sh)"

# shred password file
shred --verbose -u --zero --iterations=3 /mnt/root/install_vars.txt

# umount -R -l /mnt
# reboot
