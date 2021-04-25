#!/bin/bash

#change to your nearest arc mirror country
MIRRORCOUNTRY="Netherlands"

sudo timedatectl set-ntp true
sudo hwclock --systohc

sudo reflector -c $MIRRORCOUNTRY -a 12 --sort rate --save /etc/pacman.d/mirrorlist

sudo firewall-cmd --add-port=1025-65535/tcp --permanent
sudo firewall-cmd --add-port=1025-65535/udp --permanent
sudo firewall-cmd --reload

sudo pacman -S --noconfirm xorg gdm gnome gnome-extra chrome-gnome-shell firefox-developer-edition simplescreenrecorder arc-gtk-theme arc-icon-theme vlc

sudo systemctl enable gdm
/bin/echo -e "\e[1;32mREBOOTING IN 5..4..3..2..1..\e[0m"
sleep 5
sudo reboot
