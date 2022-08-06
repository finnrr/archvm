#!/usr/bin/env -S zsh -s

# SYSTEM TUNING, would not recommend copy pasting this stuff. 

# lower swapiness
sysctl vm.swappiness=10

# disable clearing of boot messages:
mkdir /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf <<EOL
[Service]
TTYVTDisallocate=no
EOL

# remove beeper
echo "..disable internal speaker"
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# set vars in profile
echo "..Setting Default Directories"
echo 'ZDOTDIR=$HOME/.config/zsh' >> /etc/zsh/zshenv
echo 'ZSH=$HOME/.config/zsh/oh-my-zsh' >> /etc/zsh/zshenv
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
PAGER=less
XDG_CURRENT_DESKTOP=sway
EOL

# pacman
echo "..customizing pacman"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 6/" /etc/pacman.conf

# # for thinkpad, max brightness brightness
echo 852 > /sys/class/backlight/intel_backlight/brightness

# # for thinkpad, get brightness function keys working
# sed -i '/^case "\$1" in/r'<(cat <<EOF
#     video/brightnessup)
#             case "\$2" in
#                     BRTUP)
#                         logger 'BrightnessUp button pressed'
#                         echo \$((\`cat /sys/class/backlight/intel_backlight/brightness\` + 106)) > /sys/class/backlight/intel_backlight/brightness
#                         ;;
#                     *)
#                         logger "ACPI action undefined: \$2"
#                         ;;
#             esac
#             ;;

#     video/brightnessdown)
#             case "\$2" in
#                     BRTDN)
#                         logger 'BrightnessDown button pressed'
#                         echo \$((\`cat /sys/class/backlight/intel_backlight/brightness\` - 106)) > /sys/class/backlight/intel_backlight/brightness
#                         ;;
#                     *)
#                         logger "ACPI action undefined: \$2"
#                         ;;
#             esac
#             ;;
# EOF
# ) /etc/acpi/handler.sh

#  "s/^BINARIES=().*/MODULES=(btrfs)/"

# CPU stuff

