# run with following command, warning will wipe drive/data:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install.sh)"

#make font big
#setfont latarcyrheb-sun32

#check internet
ping 8.8.8.8 -c 1

#update
pacman -Syy

#get time
timedatectl set-ntp true

#partition 100MB boot / rest
sgdisk --zap-all /dev/sda
sgdisk -n 0:0:+100MiB -t 0:ef00 -c 0:efi /dev/sda
sgdisk -n 0:0:0 -t 0:8300 -c 0:root /dev/sda
#format
mkfs.vfat -F32 -n EFI /dev/sda1
mkfs.btrfs -L ROOT /dev/sda2 -f

#mount and make subvolumes
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/swap
btrfs subvolume create /mnt/snaps
# btrfs subvolume list /mnt
umount -R /mnt
#remount with flags
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=root /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,swap}
mount -o noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol=home /dev/sda2 /mnt/home
mount -o noatime,nodiratime,compress=no,space_cache=v2,ssd,subvol=swap /dev/sda2 /mnt/swap
mount /dev/sda1 /mnt/boot
#have a looksy
findmnt -nt btrfs
lsblk

# make swap
chattr +C /mnt/swap/
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=8196 status=progress
chmod 0600 /mnt/swap/swapfile
mkswap -U clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile
#check it
btrfs subvolume list -p -t /mnt



