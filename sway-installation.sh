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
sudo pacman -S xorg-xwayland firefox-developer-edition wget zsh unrar docker docker-compose smbclient playerctl file-roller blueman alacritty vlc zathura zathura-cb zathura-pdf-mupdf thunderbird libreoffice-fresh libreoffice-fresh-nl nautilus sway swaylock swayidle

# Install Paru
cd ~; git clone https://aur.archlinux.org/paru; cd ~/paru; makepkg -si; rm -rf ~/paru

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
paru -S --noconfirm sxiv
paru -S --noconfirm ttf-material-design-icons-desktop-git
paru -S --noconfirm mako-git
paru -S --noconfirm wofi
paru -S --noconfirm waybar

# Flatpak software
sudo flatpak install -y spotify

#sudo systemctl enable --now auto-cpufreq
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

# Install Dotfiles
git clone --bare https://github.com/meyvin/dotfiles.git $HOME/.dotfiles
function config {
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
mkdir -p $HOME/.dotfiles-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} $HOME/.dotfiles-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no

# Switch to zsh
zsh

# Switch to Sway branch
dotfiles checkout sway

# install zsh snap plugin manager
git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git
source zsh-snap/install.zsh

# Set Gnome theme
gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-blue-dark'
