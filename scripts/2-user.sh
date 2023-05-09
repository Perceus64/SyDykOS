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

Installing AUR Softwares
"
source $HOME/SyDykOS/configs/setup.conf


sed -n '/'$INSTALL_TYPE'/q;p' ~/SyDykOS/pkg-files/${DESKTOP_ENV}.txt | while read line
do
  if [[ ${line} == '--END OF LIGHT INSTALL--' ]]
  then
    
    continue
  fi
  echo "INSTALLING: ${line}"
  sudo pacman -S --noconfirm --needed ${line}
done


if [[ ! $AUR_HELPER == none ]]; then
  cd ~
  git clone "https://aur.archlinux.org/$AUR_HELPER.git"
  cd ~/$AUR_HELPER
  makepkg -si --noconfirm
  
  sed -n '/'$INSTALL_TYPE'/q;p' ~/SyDykOS/pkg-files/aur-pkgs.txt | while read line
  do
    if [[ ${line} == '--END OF LIGHT INSTALL--' ]]; then
      
      continue
    fi
    echo "INSTALLING: ${line}"
    $AUR_HELPER -S --noconfirm --needed ${line}
  done
fi

export PATH=$PATH:~/.local/bin


if [[ $INSTALL_TYPE == "FULL" ]]; then
  if [[ $DESKTOP_ENV == "kde" ]]; then
    cp -r ~/SyDykOS/configs/.config/* ~/.config/
    pip install konsave
    konsave -i ~/SyDykOS/configs/sydyk.knsv
    sleep 1
    konsave -a sydyk
fi

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
