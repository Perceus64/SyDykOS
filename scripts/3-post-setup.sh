#!/usr/bin/env bash

echo -ne "
-------------------------------------------------------------------------

        ░██████╗██╗░░░██╗██████╗░██╗░░░██╗██╗░░██╗░█████╗░░██████╗
        ██╔════╝╚██╗░██╔╝██╔══██╗╚██╗░██╔╝██║░██╔╝██╔══██╗██╔════╝
        ╚█████╗░░╚████╔╝░██║░░██║░╚████╔╝░█████═╝░██║░░██║╚█████╗░
        ░╚═══██╗░░╚██╔╝░░██║░░██║░░╚██╔╝░░██╔═██╗░██║░░██║░╚═══██╗
        ██████╔╝░░░██║░░░██████╔╝░░░██║░░░██║░╚██╗╚█████╔╝██████╔╝
        ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═════╝░

-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source ${HOME}/SyDykOS/configs/setup.conf

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi


echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Login Display Manager
-------------------------------------------------------------------------
"
#check later
if [[ ${DESKTOP_ENV} == "kde" ]]; then
  systemctl enable sddm.service
  if [[ ${INSTALL_TYPE} == "FULL" ]]; then
    echo [Theme] >>  /etc/sddm.conf
    echo Current=sweet >> /etc/sddm.conf
  fi

elif [[ "${DESKTOP_ENV}" == "gnome" ]]; then
  systemctl enable gdm.service

else
  if [[ ! "${DESKTOP_ENV}" == "server"  ]]; then
  sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter
  systemctl enable lightdm.service
  fi
fi

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"

systemctl enable ntpd.service
echo "  NTP enabled"
systemctl disable dhcpcd.service
echo "  DHCP disabled"
systemctl stop dhcpcd.service
echo "  DHCP stopped"
systemctl enable NetworkManager.service
echo "  NetworkManager enabled"
systemctl enable bluetooth
echo "  Bluetooth enabled"
systemctl enable avahi-daemon.service
echo "  Avahi enabled"

echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Plymouth Boot Splash
-------------------------------------------------------------------------
"
#check later
PLYMOUTH_THEMES_DIR="$HOME/SyDykOS/configs/usr/share/plymouth/themes"
PLYMOUTH_THEME="Arch-logo-plymouth" # can grab from config later if we allow selection
mkdir -p /usr/share/plymouth/themes
echo 'Installing Plymouth theme...'
cp -rf ${PLYMOUTH_THEMES_DIR}/${PLYMOUTH_THEME} /usr/share/plymouth/themes

plymouth-set-default-theme -R Arch-logo-plymouth # sets the theme and runs mkinitcpio
echo 'Plymouth theme installed'

echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r $HOME/SyDykOS
rm -r /home/$USERNAME/SyDykOS

# Replace in the same state
cd $pwd
