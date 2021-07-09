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
sudo pacman -Syuu

# Basic Window Manager
sudo pacman -S xorg-wayland qt6-wayland firefox-developer-edition nitrogen picom wget zsh unrar docker docker-compose
flameshot ranger smbclient playerctl file-roller blueman alacritty vlc scrot
zathura thunderbird libreoffice-fresh libreoffice-fresh-nl 
nordic-theme tela-icon-theme

# Install the AUR helper Paru
cd ~
git clone https://aur.archlinux.org/paru.git
cd paru/
makepkg -si --noconfirm
rm -r ~/paru

# Install personal AUR packages
paru -S --noconfirm checkupdates+aur
paru -S --noconfirm ferdi-bin
paru -S --noconfirm gitflow-avh
paru -S --noconfirm intellij-idea-ultimate-edition
paru -S --noconfirm intellij-idea-ultimate-edition-jre
paru -S --noconfirm libxft-bgra
paru -S --noconfirm nerd-fonts-complete
paru -S --noconfirm otf-monaco-powerline-font-git
paru -S --noconfirm postman-bin
paru -S --noconfirm siji
paru -S --noconfirm timeshift
paru -S --noconfirm timeshift-autosnap
paru -S --noconfirm ttf-font-awesome
paru -S --noconfirm visual-studio-code-bin
paru -S --noconfirm nordic-theme
paru -S --noconfirm tela-icon-theme
paru -S --noconfirm dunst
paru -S --noconfirm sxiv
#paru -S --noconfirm auto-cpufreq

# Flatpak software
sudo flatpak install -y spotify

#sudo systemctl enable --now auto-cpufreq
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

# Install Dotfiles
git clone https://github.com/meyvin/dotfiles.git ~/Dotfiles
cd ~/Dotfiles; chmod +x install.sh; ./install.sh

# Set Gnome theme
gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-blue-dark'

/bin/echo -e "\e[1;32mStarting DWM  in 5..4..3..2..1..\e[0m"
sleep 5
startx
