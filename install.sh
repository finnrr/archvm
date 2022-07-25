# run with following command, warning will wipe drive/data:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install.sh)"

# make font big
# setfont latarcyrheb-sun32
# or
# pacman -S terminus-font
# setfont ter-v32b

# check internet
# ping 8.8.8.8 -c 1
# ip -c a

# update
pacman -Syy

# get time
timedatectl set-ntp true

# partition 512MB boot / rest, you'll need more for multiboot or encryption
wipefs -a /dev/sda
sgdisk --zap-all /dev/sda
sgdisk -n 0:0:+128MiB -a 4096 -t 0:ef00 -c 0:efi /dev/sda
# sgdisk -n 0:0:0 -t 0:8300 -c 0:root /dev/sda

# 
end_position=$(sgdisk -E /dev/sda)
sgdisk -a 4096 -n2:0:$(( $end_position - ($end_position + 1) % 4096 )) -t 0:8300 /dev/sda


# set up encrypted drive / use below for batch install
# echo "password" | cryptsetup -q luksFormat /dev/sda2
cryptsetup luksFormat -qyv --iter-time 500 --key-size 256 --sector-size 4096 --type luks2 /dev/sda2

# open encrypted drive / use below for batch install / drive1 can be renamed
# echo "password" | cryptsetup open /dev/sda2 drive1
cryptsetup open /dev/sda2 drive1

# format
mkfs.vfat -F32 -n EFI /dev/sda1
# mkfs.btrfs -L ROOT /dev/sda2 -f
mkfs.btrfs -L ROOT /dev/mapper/drive1

# mount and make subvolumes
# mount /dev/sda2 /mnt
mount /dev/mapper/drive1 /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/tmp
btrfs subvolume create /mnt/log
btrfs subvolume create /mnt/pkg
btrfs subvolume create /mnt/swap
btrfs subvolume create /mnt/snaps
# btrfs subvolume list /mnt
umount -R /mnt

# remount with flags
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=root /dev/sda2 /mnt
# mkdir -p /mnt/{boot,home,swap,/var/tmp,/var/log,/var/cache/pacman/pkg,.snapshots}
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=home /dev/sda2 /mnt/home
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=tmp /dev/sda2 /mnt/var/tmp
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=log /dev/sda2 /mnt/var/log
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=pkg /dev/sda2 /mnt/var/cache/pacman/pkg/
# mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=snaps /dev/sda2 /mnt/.snapshots
# mount -o noatime,nodiratime,compress=no,space_cache=v2,ssd,subvol=swap /dev/sda2 /mnt/swap
# mount /dev/sda1 /mnt/boot

mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=root /dev/mapper/drive1 /mnt
mkdir -p /mnt/{boot,home,swap,/var/tmp,/var/log,/var/cache/pacman/pkg,.snapshots}
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=home /dev/mapper/drive1 /mnt/home
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=tmp /dev/mapper/drive1 /mnt/var/tmp
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=log /dev/mapper/drive1 /mnt/var/log
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=pkg /dev/mapper/drive1 /mnt/var/cache/pacman/pkg/
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=snaps /dev/mapper/drive1 /mnt/.snapshots
mount -o noatime,nodiratime,compress=no,space_cache=v2,ssd,subvol=swap /dev/mapper/drive1 /mnt/swap
mount /dev/sda1 /mnt/boot

# check it
# findmnt -nt btrfs
# lsblk

# make swap
chattr +C /mnt/swap/
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8196 status=progress
chmod 0600 /mnt/swap/swapfile
mkswap -U clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# check it
# btrfs subvolume list -p -t /mnt

# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install_second.sh)"