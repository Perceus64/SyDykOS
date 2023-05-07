#!/usr/bin/env bash

source $HOME/SyDykOS/configs/setup.conf

  cd ~
  mkdir "/home/$USERNAME/.cache"
  touch "/home/$USERNAME/.cache/zshhistory"
  git clone "https://github.com/ChrisTitusTech/zsh"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  ln -s "~/zsh/.zshrc" ~/.zshrc

echo "Installing all packages"
sudo pacman -S --noconfirm --needed $(cat ~/SyDykOS/pkg-files/pacman-pkgs.txt)

cd ~
git clone "https://aur.archlinux.org/$AUR_HELPER.git"
cd ~/$AUR_HELPER
makepkg -si --noconfirm

echo "Installing AUR helper"
$AUR_HELPER -S --noconfirm --needed $(cat ~/SyDykOS/pkg-files/aur-pkgs.txt)


export PATH=$PATH:~/.local/bin

#theming kde
echo "Theming KDE"
cp -r ~/SyDykOS/configs/.config/* ~/.config/
pip install konsave
konsave -i ~/SyDykOS/configs/sydyk.knsv
sleep 1
konsave -a sydyk

exit
