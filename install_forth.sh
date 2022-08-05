source  /root/install_vars.txt

# user_name=$1
echo "..user name is $user_name"
# user_pass=$2
echo "..user password is set"

# USER AND SOFTWARE:

# add users and set root password
echo "..add user $user_name"
useradd -m -G wheel -s /usr/bin/zsh $user_name
echo "$user_name:$user_pass" | chpasswd 
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers


git clone https://aur.archlinux.org/paru.git /home/$user_name/paru
chown $user_name /home/$user_name/paru
cd /home/$user_name/paru
su -c "makepkg -si --noconfirm" -s /bin/sh $user_name
cd /home/$user_name
rm -r /home/$user_name/paru


# make some dirs
mkdir -p /home/$user_name/.config/{zsh,sway}

# SOFTWARE TIME:

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


# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"



# add to shell :
# if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
#   exec sway
# fi