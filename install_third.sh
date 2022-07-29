#update keyring
pacman -S archlinux-keyring reflector 
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu

# install drivers
pacman --noconfirm -Syu bluez bluez-utils xf86-input-synaptics

# install sway desktop
pacman -S sway wayland foot

# sound pipewire-alsa pipewire-pulse 
pacman -S pipewire wireplumber 

# utils and programming
pacman -S python python-pip git wget hwdetect 

# software
# pacman -S firefox discord 

# remove install files
pacman -Scc

# remove orphans
pacman -Qtdq | pacman -Rns -

# enable bluetooth
echo AutoEnable=true >> /etc/bluetooth/main.conf
systemctl enable bluetooth.service

# sway 
systemctl enable seatd.service 

# add users and set root password
echo Set Root Password
passwd root
echo "Set Password for $User_Name"
useradd -m -G wheel,seat -s /usr/bin/zsh $User_Name
passwd $User_Name
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# # for thinkpad, max brightness brightness
# echo 852 > /sys/class/backlight/intel_backlight/brightness

# # for thinkpad, get brightness function keys working
# sed '/^CHANGETHIS$/r'<(cat <<EOF
# video/brightnessup)
#             case "$2" in
#                     BRTUP)
#                         logger 'BrightnessUp button pressed'
#                         echo $((`cat /sys/class/backlight/intel_backlight/brightness` + 106)) > /sys/class/backlight/intel_backlight/brightness
#                         ;;
#                     *)
#                         logger "ACPI action undefined: $2"
#                         ;;
#             esac
#             ;;

#     video/brightnessdown)
#             case "$2" in
#                     BRTDN)
#                         logger 'BrightnessDown button pressed'
#                         echo $((`cat /sys/class/backlight/intel_backlight/brightness` - 106)) > /sys/class/backlight/intel_backlight/brightness
#                         ;;
#                     *)
#                         logger "ACPI action undefined: $2"
#                         ;;
#             esac
#             ;;
# EOF
# ) -i -- /etc/acpi/handler.sh

