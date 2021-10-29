#!/bin/bash

################################################################################
#### Gnome                                                                  ####
################################################################################
mirror_country="Netherlands"

echo "Retrieve and filter the latest Pacman mirror list for ${mirror_country}"
reflector -c $mirror_country -a 12 --sort rate --save /etc/pacman.d/mirrorlist

echo "Installing Gnome Desktop Environment"
sudo pacman -S \
docker \
docker-compose \
firefox-developer-edition \
gnome \
gnome-extra \
smbclient \
thunderbird \
unrar \
vlc \
wget \
zsh

################################################################################
#### Firwall                                                                ####
################################################################################
echo "Setting up Firewall"
firewall-cmd --add-port=1025-65535/tcp --permanent
firewall-cmd --add-port=1025-65535/udp --permanent
firewall-cmd --reload

################################################################################
#### Paru aur package manager installation                                  ####
################################################################################
echo "Installing Paru Aur package manager"
git clone https://aur.archlinux.org/paru $HOME/paru
cd ~/paru
makepkg -si ~/paru
rm -rf ~/paru

################################################################################
#### AUR Packages                                                           ####
################################################################################
echo "Installing AUR packages"
paru -S \
adobe-base-14-fonts \
chrome-gnome-shell \
ferdi-bin \
gitflow-avh \
gnome-shell-extension-arc-menu \
gnome-shell-extension-dash-to-panel-git \
gnome-shell-extension-ddterm
intellij-idea-ultimate-edition \
intellij-idea-ultimate-edition-jre \
nerd-fonts-complete \
nordic-theme-git \
otf-monaco-powerline-font-git \
postman-bin \
spotify \
tela-icon-theme \
ttf-font-awesome \
ttf-material-design-icons-desktop-git \
yadm-git

################################################################################
#### Flatpak packages                                                       ####
################################################################################
echo "Install Flatpak software"
sudo flatpak install -y org.gnome.Extensions

################################################################################
#### Gnome extensions                                                       ####
################################################################################

gnome-extensions disable apps-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable drive-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable launch-new-instance@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable native-window-placement@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable places-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable window-list@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable windowsNavigator@gnome-shell-extensions.gcampax.github.com
gnome-extensions disable workspace-indicator@gnome-shell-extensions.gcampax.github.com

gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable dash-to-panel@jderose9.github.com
gnome-extensions enable ddterm@amezin.github.com
gnome-extensions enable arcmenu@arcmenu.com
gnome-extensions enable auto-move-windows@gnome-shell-extensions.gcampax.github.com

################################################################################
#### Enabling Docker                                                        ####
################################################################################
echo "Enabling Docker"
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

################################################################################
#### Installing Dotfiles                                                    ####
################################################################################
echo "Installing Dotfiles"
cd ~;yadm clone -b gnome https://github.com/meyvin/dotfiles.git

################################################################################
#### Gnome Theming                                                          ####
################################################################################
echo "Enabling Gnome theme, icons, wallpaper and gdm"
gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-blue-dark'
gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.shell.keybindings switch-to-application-5 '[]'
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 '["<Super>5"]'
gsettings set org.gnome.desktop.background picture-uri ~/wallpaper.png

git clone https://github.com/arcticicestudio/nord-gnome-terminal.git /tmp/nord-gnome-terminal
/tmp/nord-gnome-terminal/src/nord.sh

sudo systemctl enable gdm.service

################################################################################
#### ZSH & Dotfiles Configuration                                           ####
################################################################################
echo "Installing ZSH-Snap plugin manager"
mkdir ~/.zsh-plugins
git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git $HOME/.zsh-plugins/zsh-snap

echo "Switch to and set ZSH as default"
chsh -s /usr/bin/zsh

echo "Reboot and start Gnome in:"
echo -e "\e[1;32m5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
