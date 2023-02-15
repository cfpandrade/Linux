#!/bin/bash

# Clear the screen
clear

# Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Functions
function header() {
  echo "${yellow}-----------------${reset}"
  echo "${yellow} $1 ${reset}"
  echo "${yellow}-----------------${reset}"
}

function install_deb_apps() {
  header "Installing local DEB apps"
  sudo apt -y install ~/Linux/apps/bat*.deb
  sudo apt -y install ~/Linux/apps/lsd*.deb
}

function install_fonts() {
  header "Installing fonts"
  mkdir ~/.fonts
  cp -r ./fonts/* ~/.fonts/
  fc-cache -f -v
}

function install_zsh() {
  header "ZSH Configuration"
  cp .zshrc ~
#   sudo mkdir /usr/share/zsh
#   sudo cp -r ./zsh/* /usr/share/zsh/
  sudo usermod --shell /usr/bin/zsh $USER
  sudo usermod --shell /usr/bin/zsh root
  header "Done"
}

function install_powerlevel10k() {
  header "PowerLevel10k"
  sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/bin/powerlevel10k
}

function install_fzf() {
  header "FZF"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --key-bindings --completion --all 
  sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes
}

# Install requirements
header "Installing requirements"
sudo apt -y install git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu snapd default-mysql-client imagemagick 
sudo apt -y install acl fortune cowsay

# Update and upgrade
header "Updating and Upgrading the system"
sudo apt update
sudo apt -y upgrade
sudo apt -y autoremove || sudo apt --fix-broken install && sudo apt -y autoremove

# Install apps
install_deb_apps

# Install fonts
install_fonts

# Install ZSH
install_zsh

# Install PowerLevel10k
install_powerlevel10k

# Install FZF
install_fzf

# Install SNAP apps
header "SNAP"
export PATH=/snap/bin:$PATH
sudo snap install searchsploit
sudo snap install mysql-shell

clear
header "Script by: Carlos Perez Andrade"
echo
fortune | cowsay 2>/dev/null
