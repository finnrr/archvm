
# lower swap
sysctl vm.swappiness=10

# enable network, change wifi name and password 
# echo -e '[Match]\nName=enp0s31f6\n[Network]\nDHCP=yes' /etc/systemd/network/20-wired.network
# echo -e '[Match]\nName=wlan0\n[Network]\nDHCP=yes' /etc/systemd/network/25-wireless.network
# systemctl enable --now systemd-networkd systemd-resolved iwd
# echo -e 'station wlan0 connect <WIFINAME> \n<WIFIPASSWORD> \nexit' iwctl 
# systemctl restart systemd-networkd

# tune network dropout time
mkdir /etc/systemd/system/systemd-networkd-wait-online.service.d
cat > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any -timeout=30
EOL

#set global vars in /etc/environment
cat > /etc/environment << EOL
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
EDITOR=nvim
VISUAL=nvim
XDG_CURRENT_DESKTOP=sway
EOL

#set vars in profile
echo ZDOTDIR=$HOME/.config/zsh >> /etc/zsh/zshenv
echo export XDG_CONFIG_HOME="$HOME/.config" >> /etc/profile 
echo export XDG_CACHE_HOME="$HOME/.cache" >> /etc/profile
echo export XDG_DATA_HOME="$HOME/.local/share" >> /etc/profile
echo export XDG_STATE_HOME="$HOME/.local/state" >> /etc/profile

#update keyring
pacman -S archlinux-keyring reflector 
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
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
pacman -S firefox discord 

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

