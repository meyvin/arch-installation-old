#!/bin/bash

sudo pacman -Syu --noconfirm docker docker-compose
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

pikaur -S --noconfirm dotnet-host-bin
pikaur -S --noconfirm dotnet-runtime-bin
pikaur -S --noconfirm dotnet-sdk-bin
pikaur -S --noconfirm gitflow-avh
pikaur -S --noconfirm intellij-idea-ultimate-edition
pikaur -S --noconfirm intellij-idea-ultimate-edition-jre
pikaur -S --noconfirm postman-bin
pikaur -S --noconfirm sublime-merge
pikaur -S --noconfirm visual-studio-code-bin

git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/plugins/zsh-syntax-highlighting
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
/bin/echo -e "\e[1;32mManually append zsh-nvm zsh-autosuggestions & zsh-syntax-highlighting to ~/.zshrc plugins()\e[0m"
