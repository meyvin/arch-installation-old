#!/bin/bash

# Install my basic software needs that are available in the arch repo
sudo pacman -Syu --noconfirm evolution guake nextcloud-client neofetch wget

# Install the AUR helper Pikaur
cd ~
git clone https://aur.archlinux.org/pikaur.git
cd pikaur/
makepkg -si --noconfirm
rm -r ~/pikaur

# Install my other basic software needs that are available in the AUR repo
pikaur -S --noconfirm appimagelauncher
#pikaur -S --noconfirm auto-cpufreq
pikaur -S --noconfirm ferdi-nightly-bin
pikaur -S --noconfirm timeshift
pikaur -S --noconfirm timeshift-autosnap
pikaur -S --noconfirm ttf-ms-fonts
pikaur -S --noconfirm ulauncher

sudo flatpak install -y spotify

#sudo systemctl enable --now auto-cpufreq

# Install Oh My ZSH
cd ~
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sh install.sh

