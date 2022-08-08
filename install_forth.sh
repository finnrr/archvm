# User setup

# source  /root/install_vars.txt
user_name=wrk
user_pass="'"
# user_name=$1
echo "..user name is $user_name"
# user_pass=$2
echo "..user password is set"

# USER AND SOFTWARE:
# change root shell
echo "..changing root shell"
sed -i "s|root:/bin/bash|root:/bin/zsh|g" /etc/passwd
touch /root/.config/zsh/.zshrc
zsh
mkdir -p /root/.config/{zsh,nvim}
chmod 700 /root/.config -R


# zpresto for root
echo "..giving root zpresto"
git clone --recursive https://github.com/sorin-ionescu/prezto.git $ZDOTDIR/.zprezto
chmod 700 $ZDOTDIR/.zprezto -R
echo 'source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"' >> /root/.config/zsh/.zshrc
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
sed -i "s|'sorin'|'skwp'|g" /root/.config/zsh/.zpreztorc
sed -i "s|'emacs'|'vi'|g" /root/.config/zsh/.zpreztorc
echo "autoload -Uz promptinit" >> /root/.config/zsh/.zshrc
echo "promptinit" >> /root/.config/zsh/.zshrc
echo "prompt damoekri" >> /root/.config/zsh/.zshrc

# default dirs
rm /etc/skel/.* -f
mkdir -p /etc/skel/.config/{zsh,sway,nvim,paru}
touch /etc/skel/.config/zsh/.zshrc

# add users and set root password
echo "..add user $user_name"
useradd -m -G wheel -s /bin/zsh $user_name
echo "$user_name:$user_pass" | chpasswd 
# give sudoers permission and bypass passwords (not recommended)
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# SOFTWARE TIME:

#update keyring
echo "..updating mirrors"
pacman -Syu --noconfirm archlinux-keyring reflector 
reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# manage thread privileges
pacman -S --noconfirm realtime-privileges
usermod -aG realtime $user_name

# install drivers
pacman -S --noconfirm bluez bluez-utils # xf86-input-synaptics

# AUR manager
pacman -S --noconfirm rustup
git clone https://aur.archlinux.org/paru.git /home/$user_name/paru
chown $user_name /home/$user_name/paru
cd /home/$user_name/paru
su -c "rustup default stable;makepkg -si --noconfirm" -s /bin/sh $user_name
cd /home/$user_name
rm -r /home/$user_name/paru
sed -i "s/^#BottomUp$/BottomUp/" /etc/paru.conf

# install sway desktop
pacman -S --noconfirm sway wayland xorg-xwayland foot

# sound pipewire-alsa pipewire-pulse 
pacman -S --noconfirm pipewire wireplumber 

# utils and programming
pacman -S --noconfirm python python-pip hwdetect 

# manuals
pacman -S --noconfirm man-db man-pages texinfo

# software
# pacman -S firefox discord 

# remove install files
pacman -Scc --noconfirm

# remove orphans
pacman -Qtdq |pacman -Rns 

# enable bluetooth
echo AutoEnable=true >> /etc/bluetooth/main.conf
systemctl enable bluetooth.service

# sway 
gpasswd -a $user_name seat
systemctl enable seatd.service 
cat >> /home/$user_name/.config/zsh/.zprofile <<EOL
if [ -z \$DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec sway
fi
EOL

# auto login
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $user_name - \$TERM
EOL
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"






