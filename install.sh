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
# #format
# mkfs.vfat -F32 -n EFI /dev/sda1
# mkfs.btrfs -L ROOT /dev/sda2 -f
# #mount and make subvolumes
# mount /dev/sda2 /mnt
# btrfs subvolume create /mnt/root
# btrfs subvolume create /mnt/home
# btrfs subvolume create /mnt/swap
# btrfs subvolume create /mnt/snaps