#!/bin/bash

# Install my basic software needs that are available in the arch repo
sudo pacman -Syu --noconfirm plank evolution guake nextcloud-client wget zsh

# Install the AUR helper Pikaur
cd ~
git clone https://aur.archlinux.org/paru.git
cd paru/
makepkg -si --noconfirm
rm -r ~/paru

# Install my other basic software needs that are available in the AUR repo
paru -Syu
paru -S --noconfirm appimagelauncher
#paru -S --noconfirm auto-cpufreq
paru -S --noconfirm ferdi-nightly-bin
paru -S --noconfirm timeshift
paru -S --noconfirm timeshift-autosnap
paru -S --noconfirm ttf-ms-fonts
paru -S --noconfirm ulauncher
paru -S --noconfirm vimix-gtk-themes-git
paru -S --noconfirm tela-icon-theme


sudo flatpak install -y spotify
sudo flatpak install -y extensions

#sudo systemctl enable --now auto-cpufreq

# Install Oh My ZSH
cd ~
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh install.sh

