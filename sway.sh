#!/bin/bash

################################################################################
#### Pacman.conf configuration                                  ####
################################################################################
sudo timedatectl set-ntp true
sudo hwclock --systohc

echo "Setting up Firewall"
sudo firewall-cmd --add-port=1025-65535/tcp --permanent
sudo firewall-cmd --add-port=1025-65535/udp --permanent
sudo firewall-cmd --reload

################################################################################
#### Pacman packages                                                        ####
################################################################################
echo "Enable Colors, Parallel Downloads and Multilib in /etc/pacman.conf"
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo sed -i '/Color/s/^#//g' /etc/pacman.conf
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

echo "Updating pacman"
sudo pacman -Syu

echo "Installing Sway Desktop Environment"
sudo pacman -S \
blueman \
brightnessctl \
docker \
docker-compose \
exa \
file-roller \
firefox-developer-edition \
fish \
foot \
gedit \
gedit-plugins \
gnome-calculator \
gnome-keyring \
jq \
nextcloud-client \
pamixer \
playerctl \
polkit-gnome \
qt5-wayland \
qt6-wayland \
smbclient \
slurp \
sway \
swayidle \
thunar \
thunar-archive-plugin \
thunar-media-tags-plugin \
thunar-volman \
thunderbird \
tumbler \
unrar \
wf-recorder \
wget \
xorg-xwayland \
zathura \
zathura-cb \
zathura-pdf-mupdf

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
avizo \
celluloid \
clipman \
gitflow-avh \
grim \
gtk-theme-bubble-darker-blue-git \
intellij-idea-ultimate-edition \
intellij-idea-ultimate-edition-jre \
kanshi \
nerd-fonts-complete \
newsflash \
nnn-nerd \
otf-monaco-powerline-font-git \
otf-font-awesome \
postman-bin \
rambox-bin \
siji \
spotify \
swappy \
sway-audio-idle-inhibit-git \
swaylock-effects \
swaync-git \
sxiv \
tela-icon-theme \
ttf-material-design-icons-desktop-git \
ttf-meslo-nerd-font-powerlevel10k \
visual-studio-code-bin \
waybar \
wofi \
xcursor-simp1e \
yadm-git \
zramd

################################################################################
#### Enabling Docker                                                        ####
################################################################################
echo "Enabling Docker"
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

################################################################################
#### Enabling Zram                                                          ####
################################################################################
sudo sed -i '/MAX_SIZE/s/^# //g' /etc/default/zramd

################################################################################
#### Gnome Theming                                                          ####
################################################################################
echo "Enabling Gnome theme and icons"
gsettings set org.gnome.desktop.interface gtk-theme 'Bubble-Darker-Blue'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'

################################################################################
#### Installing Dotfiles                                                    ####
################################################################################
echo "Installing Dotfiles"
cd ~;yadm clone https://github.com/meyvin/dotfiles.git

################################################################################
#### Enable systemd services                                                ####
################################################################################
sudo systemctl enable --user kanshi
sudo systemctl enable zramd

################################################################################
#### Start ssh-agent                                                        ####
################################################################################
eval `ssh-agent -s`

################################################################################
#### ZSH & Dotfiles Configuration                                           ####
################################################################################
echo "Switch to and set Fish as default"
chsh -s /usr/bin/fish

echo "Reboot and start Sway in:"
echo -e "\e[1;32m5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
