#!/bin/bash

#change to your nearest arc mirror country
MIRRORCOUNTRY="Netherlands"

sudo timedatectl set-ntp true
sudo hwclock --systohc

sudo reflector -c $MIRRORCOUNTRY -a 12 --sort rate --save /etc/pacman.d/mirrorlist

sudo firewall-cmd --add-port=1025-65535/tcp --permanent
sudo firewall-cmd --add-port=1025-65535/udp --permanent
sudo firewall-cmd --reload

# Enable Multilib
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Syu

# Basic Window Manager
sudo pacman -S xorg-server xorg-xinit xorg-xrandr xorg-xsetroot firefox-developer-edition nitrogen picom wget zsh unrar docker docker-compose flameshot ranger smbclient playerctl thunar thunar-archive-manager file-roller evolution 

# Install the AUR helper Paru
cd ~
git clone https://aur.archlinux.org/paru.git
cd paru/
makepkg -si --noconfirm
rm -r ~/paru

# Install personal AUR packages
paru -S --noconfirm appimagelauncher
paru -S --noconfirm dotnet-host-bin
paru -S --noconfirm dotnet-runtime-bin
paru -S --noconfirm dotnet-sdk-bin
paru -S --noconfirm ferdi-bin
paru -S --noconfirm gitflow-avh
paru -S --noconfirm intellij-idea-ultimate-edition
paru -S --noconfirm intellij-idea-ultimate-edition-jre
paru -S --noconfirm joplin-desktop
paru -S --noconfirm nerd-fonts-complete
paru -S --noconfirm otf-monaco-powerline-font-git
paru -S --noconfirm postman-bin
paru -S --noconfirm siji
paru -S --noconfirm sublime-merge
paru -S --noconfirm timeshift
paru -S --noconfirm timeshift-autosnap
paru -S --noconfirm ttf-font-awesome
paru -S --noconfirm visual-studio-code-bin
#paru -S --noconfirm auto-cpufreq

# Flatpak software
sudo flatpak install -y spotify


#sudo systemctl enable --now auto-cpufreq
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

# Install DWM
cd ~
git clone https://github.com/meyvin/dwm-environment.git .dwm
cd ~/.dwm/dwm-6.2
sudo cp config.def.h config.h && make && sudo make clean install
cd ~/.dwm/dmenu
sudo cp config.def.h config.h && make && sudo make clean install
cd ~/.dwm/st
sudo cp config.def.h config.h && make && sudo make clean install
chmod +x ~/.dwm/dwm-bar/dwm_bar.sh
ln -s ~/.dwm/.xinitrc ~/.xinitrc

/bin/echo -e "\e[1;32mStarting DWM  in 5..4..3..2..1..\e[0m"
sleep 5
startx
