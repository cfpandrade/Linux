#!/bin/bash
clear

# Variables
FONTS_DIR="$HOME/.fonts"
ZSH_DIR="/usr/share/zsh"
POWERLEVEL10K_DIR="/usr/bin/powerlevel10k"
FZF_DIR="$HOME/.fzf"
TMUX_DIR="$HOME/.tmux"

# Update/Upgrade
echo "$(tput setaf 5)---------------------------------"
echo "Updating and Upgrading the system"
echo "---------------------------------$(tput sgr 0)"
sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove

# Install requirements
echo "$(tput setaf 5)------------------------"
echo 'Installing requirements'
echo "------------------------$(tput sgr 0)"
sudo apt -y install zsh git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu snapd default-mysql-client imagemagick fortune cowsay

# Install apps
echo "$(tput setaf 5)---------------"
echo 'Installing local apps'
echo "---------------$(tput sgr 0)"
sudo apt -y install ~/Linux/apps/*.deb

# Install fonts
echo "$(tput setaf 5)----------------"
echo 'Installing fonts'
echo "----------------$(tput sgr 0)"
mkdir -p "$FONTS_DIR"
cp -r ./fonts/* "$FONTS_DIR"
fc-cache -f -v

# ZSH conf
echo "$(tput setaf 5)-----------------"
echo 'ZSH Configuration'
echo "-----------------$(tput sgr 0)"
cp .zshrc ~
sudo mkdir -p "$ZSH_DIR"
sudo cp -r ./zsh/* "$ZSH_DIR"

# Installing whichSystem
echo "$(tput setaf 5)----------------------"
echo 'Installing whichSystem'
echo "----------------------$(tput sgr 0)"
sudo cp ./apps/whichSystem.py /usr/bin/
sudo chmod +x /usr/bin/whichSystem.py
echo "whichSystem Installed"

# ZSH as default
echo "$(tput setaf 5)-------------------------------"
echo 'Making ZSH default for everyone'
echo "-------------------------------$(tput sgr 0)"
sudo usermod --shell /usr/bin/zsh $USER
sudo usermod --shell /usr/bin/zsh root

# Solve issues when you migrate from root to a lower privileged user
echo "$(tput setaf 5)-------------------------------------------------------"
echo 'Solving an issue when migrate from root to a lower user'
echo "-------------------------------------------------------$(tput sgr 0)"
sudo setfacl -m u:$USER:rwx

# Powerlevel10k
echo "$(tput setaf 5)---------------"
echo "PowerLevel10k"
echo "---------------$(tput sgr 0)"
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_DIR"

# Installing SNAP apps
echo "$(tput setaf 5)---------------"
echo "SNAP"
echo
