#!/bin/bash

sudo pacman -Syu --noconfirm docker docker-compose
sudo systemctl enable docker.service
sudo usermod -aG docker $USER

paru -S --noconfirm dotnet-host-bin
paru -S --noconfirm dotnet-runtime-bin
paru -S --noconfirm dotnet-sdk-bin
paru -S --noconfirm gitflow-avh
paru -S --noconfirm intellij-idea-ultimate-edition
paru -S --noconfirm intellij-idea-ultimate-edition-jre
paru -S --noconfirm postman-bin
paru -S --noconfirm sublime-merge
paru -S --noconfirm visual-studio-code-bin

git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
/bin/echo -e "\e[1;32mManually append zsh-nvm zsh-autosuggestions zsh-syntax-highlighting to ~/.zshrc plugins()\e[0m"
