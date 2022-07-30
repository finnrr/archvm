#!/usr/bin/env -S zsh -s

# Not finished.

# UEFI Keys

# generate keys 
pacman -S --noconfirm efitools sbsigntools 

# gen random key
cd /root
uuidgen --random > GUID.txt

# platform key
openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 36500 -subj "/CN=my Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth

# sign empty file
sign-efi-sig-list -g "$(< GUID.txt)" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

# key exchange key
openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 36500 -subj "/CN=my Key Exchange Key/" -out KEK.crt
openssl x509 -outform DER -in KEK.crt -out KEK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

# Signature Database key
openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 36500 -subj "/CN=my Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k KEK.key -c KEK.crt db db.esl db.auth

cp /root/*.{cer,esl,auth} /efi/

# autosign EFI using pacman

mkdir /etc/pacman.d/hooks


cat > /etc/pacman.d/hooks/99-secureboot.hook <<EOL
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOL

cat > /etc/pacman.d/hooks/99-secureboot.hook <<EOL
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/initcpio/*
[Action]
Description = Signing EFI executables for SecureBoot...
When = PostTransaction
Exec = /usr/bin/find /efi/EFI/Arch -type f ( -name *.efi ) \
-exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null \
| /usr/bin/grep -q "signature certificates"; then /usr/bin/sbsign \
--key /root/db.key --cert /root/db.crt -- output "\$1" "\$1"; fi' _ {} ;
Depends = sbsigntools
Depends = findutils
Depends = grep
EOL

# secure boot
# copy keys
# cp /root/*.{cer,esl,auth} /efi/
# 3.14.4.2 Boot into UEFI firmware setup utility & Go to Secure Boot options
# systemctl reboot --firmware
# OR by hitting the [F2] or [Del] key at boot.
# > Activate vendor specific settings like "Expert Key Management".
# 3.14.4.3 Backup & Delete preloaded Secure Boot keys
# > Save your Secure Boot keys! (ALT)
# > Delete all preloaded Secure Boot keys: ALL or db -> KEK -> PK
# (Secure Boot is now in "Setup Mode")
# 3.14.4.4 Enroll db, KEK and PK certificates
# > Set or append the new keys: db -> KEK -> PK
# (Secure Boot is now in "User Mode")
# Note: If supported use .auth and .esl over .cer.
# 3.14.5 Set UEFI supervisor (administrator) password
# ... to protect the firmware settings.
# 3.14.6 Reboot & Verify Secure Boot status
# od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot*
# > Output e.g.: 6 0 0 0 1 (1 as the final integer)



