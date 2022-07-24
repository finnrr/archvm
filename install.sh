#make font big
setfont latarcyrheb-sun32

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
findmnt -nt btrfs
lsblk
