#!/bin/bash

################################################################################
#### Mirrors and Pacman.conf configuration                                  ####
################################################################################
MIRRORCOUNTRY="Netherlands"

sudo timedatectl set-ntp true
sudo hwclock --systohc

echo "Retrieve and filter the latest Pacman mirror list for ${MIRRORCOUNTRY}"
sudo reflector -c $MIRRORCOUNTRY -a 12 --sort rate --save /etc/pacman.d/mirrorlist

echo "Setting up Firewall"
sudo firewall-cmd --add-port=1025-65535/tcp --permanent
sudo firewall-cmd --add-port=1025-65535/udp --permanent
sudo firewall-cmd --reload

################################################################################
#### Pacman packages                                                        ####
################################################################################
echo "Enable Colors, Parallel Downloads and Multilib in /etc/pacman.conf"
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sed -i '/Color/s/^#//g' /etc/pacman.conf
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

echo "Updating pacman"
sudo pacman -Syu

echo "Installing Sway Desktop Environment"
sudo pacman -S \
adobe-base-14-fonts \
alacritty \
blueman \
docker \
docker-compose \
file-roller \
firefox-developer-edition \
gammastep \
grub-btrfs \
jq \
lib32-libva-mesa-driver \
lib32-mesa \
lib32-mesa-vdpau \
lib32-vulkan-radeon \
libreoffice-fresh \
libreoffice-fresh-nl \
libva-mesa-driver \
nautilus \
mesa \
mesa-vdpau \
playerctl \
qt5-wayland \
qt6-wayland \
smbclient \
slurp \
sway \
swayidle \
swaylock \
thunar \
thunar-archive-plugin \
thunar-media-tags-plugin \
thunar-volman \
thunderbird \
unrar \
virtualbox \
virtualbox-host-modules-arch \
vlc \
vulkan-radeon \
wget \
xf86-video-amdgpu \
xorg-xwayland \
zathura \
zathura-cb \
zathura-pdf-mupdf \
zsh

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
ferdi-bin \
gitflow-avh \
intellij-idea-ultimate-edition \
intellij-idea-ultimate-edition-jre \
mako-git \
nerd-fonts-complete \
nordic-theme \
otf-monaco-powerline-font-git \
postman-bin \
siji \
swappy \
sxiv \
tela-icon-theme \
timeshift \
timeshift-autosnap \
ttf-font-awesome \
ttf-material-design-icons-desktop-git \
visual-studio-code-bin \
waybar \
wofi

################################################################################
#### Timeshift Grub-BTRFS                                                   ####
################################################################################
sudo timeshift --create
sudo pacman -S grub-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg

################################################################################
#### Flatpak packages                                                       ####
################################################################################
echo "Install Flatpak software"
sudo flatpak install -y spotify

################################################################################
#### Enabling Docker                                                        ####
################################################################################
echo "Enabling Docker"
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

################################################################################
#### Gnome Theming                                                          ####
################################################################################
echo "Enabling Gnome theme and icons"
gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-blue-dark'

################################################################################
#### Installing Dotfiles                                                    ####
################################################################################
echo "Installing Dotfiles"
cd ~;git clone --bare https://github.com/meyvin/dotfiles.git $HOME/.dotfiles
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout sway
/usr/bin/git config status.showUntrackedFiles no

################################################################################
#### ZSH & Dotfiles Configuration                                           ####
################################################################################
echo "Installing ZSH-Snap plugin manager"
git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git $HOME/zsh-snap

echo "Switch to and set ZSH as default"
chsh -s /usr/bin/zsh
zsh
source ~/zsh-snap/znap.zsh

echo "Reboot and start Sway in:"
echo -e "\e[1;32m5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
