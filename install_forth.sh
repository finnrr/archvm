source  /root/install_vars.txt


# user_name=$1
echo "..user name is $user_name"
# user_pass=$2
echo "..user password is set"

# SYSTEM SETUP:

#set global vars in /etc/environment
echo "..Setting Global Vars"
cat > /etc/environment << EOL
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
EDITOR=nvim
VISUAL=nvim
XDG_CURRENT_DESKTOP=sway
EOL

#set vars in profile
echo "..Setting Default Directories"
echo 'ZDOTDIR=$HOME/.config/zsh' >> /etc/zsh/zshenv
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile

# add users and set root password
echo "..add user $user_name"
useradd -m -G wheel -s /usr/bin/zsh $user_name
echo "$user_name:$user_pass" | chpasswd 
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# make some dirs
mkdir -p /home/$user_name/.config/{zsh,sway}

# SOFTWARE TIME:
echo "..make pacman better"
sed -i 's/#UseSyslog/UseSyslog/' /etc/pacman.conf 
sed -i 's/#Color/Color\\\nILoveCandy/' /etc/pacman.conf 
sed -i 's/Color\\/Color/' /etc/pacman.conf 
sed -i 's/#CheckSpace/CheckSpace/' /etc/pacman.conf
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf

#update keyring
echo "..updating mirrors"
pacman -S --noconfirm archlinux-keyring reflector git
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu

# install drivers
pacman -S --noconfirm bluez bluez-utils xf86-input-synaptics sof-firmware

# install sway desktop
pacman -S --noconfirm sway wayland foot

# sound pipewire-alsa pipewire-pulse 
pacman -S --noconfirm pipewire wireplumber 

# utils and programming
pacman -S --noconfirm python python-pip git wget hwdetect 

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
gpasswd -a $user_name seat
systemctl enable seatd.service 
cat > /home/$user_name/.config/zsh/.zshrc <<EOL
if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec sway
fi
EOL


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

# add to shell :
# if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#   exec sway
# fi