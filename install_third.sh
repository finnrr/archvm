#!/usr/bin/env -S zsh -s

# SYSTEM TUNING

# lower swapiness
sysctl vm.swappiness=10

# disable clearing of boot messages:
cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf <<EOL
[Service]
TTYVTDisallocate=no
EOL

# remove beeper
echo "disable internal speaker"
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# TTY font
pacman -S --noconfirm tamsyn-font
setfont tamsyn10x20r
echo "FONT=Tamsyn10x20r" > /etc/vconsole.conf

# set vars in profile
echo "..Setting Default Directories"
echo 'ZDOTDIR=$HOME/.config/zsh' >> /etc/zsh/zshenv
echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> /etc/profile
echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> /etc/profile
echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> /etc/profile
echo 'export XDG_STATE_HOME="$HOME/.local/state"' >> /etc/profile

# set global vars in /etc/environment
echo "..Setting Global Vars"
cat > /etc/environment << EOL
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
MOZ_ENABLE_WAYLAND=1
EDITOR=nvim
VISUAL=nvim
XDG_CURRENT_DESKTOP=sway
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

# CPU stuff

