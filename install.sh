# run with following command, warning will wipe drive/data:
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install.sh)"

installdrive=/dev/sda
drive_name=drive1
swap_size=8196

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
wipefs -a $installdrive
sgdisk --zap-all $installdrive
sgdisk -n 0:0:+128MiB -a 4096 -t 0:ef00 -c 0:efi $installdrive
# for no encryption:
# sgdisk -n 0:0:0 -t 0:8300 -c 0:root $installdrive

# make sure rest of drive is in 4096 sized blocks for encryption
end_position=$(sgdisk -E $installdrive)
sgdisk -a 4096 -n2:0:$(( $end_position - ($end_position + 1) % 4096 )) -t 0:8300 $installdrive


# set up encrypted drive / use below for batch install
# echo "password" | cryptsetup -q luksFormat /dev/sda2
cryptsetup luksFormat -qyv --iter-time 500 --key-size 256 --sector-size 4096 --type luks2 "$installdrive"2

# open encrypted drive
# echo "password" | cryptsetup open /dev/sda2 drive1
cryptsetup open "$installdrive"2 $drive_name

drive_path=/dev/mapper/$drive_name

# format
mkfs.vfat -F32 -n EFI "$installdrive"1
mkfs.btrfs -L ROOT $drive_path -f

# mount and make subvolumes to /mnt
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
mount_vars="noatime,nodiratime,compress=zstd,space_cache=v2,ssd,subvol="
mount -o "$mount_vars"root $drive_path /mnt
mkdir -p /mnt/{boot,home,swap,/var/tmp,/var/log,/var/cache/pacman/pkg,.snapshots}
mount -o "$mount_vars"home $drive_path /mnt/home
mount -o "$mount_vars"tmp $drive_path /mnt/var/tmp
mount -o "$mount_vars"log $drive_path /mnt/var/log
mount -o "$mount_vars"pkg $drive_path /mnt/var/cache/pacman/pkg/
mount -o "$mount_vars"snaps $drive_path /mnt/.snapshots
mount -o "$mount_vars"swap $drive_path /mnt/swap
mount "$installdrive"1 /mnt/boot

# check it
# findmnt -nt btrfs
# lsblk

# make swap
chattr +C /mnt/swap/
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=$swap_size status=progress
chmod 0600 /mnt/swap/swapfile
mkswap -U clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# check it
# btrfs subvolume list -p -t /mnt

# sh -c "$(curl -fsSL https://raw.githubusercontent.com/finnrr/archvm/main/install_second.sh)"