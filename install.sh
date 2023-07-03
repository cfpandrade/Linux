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
  local line=$(printf '%*s' "${#1}" '' | tr ' ' '=')
  echo ""
  echo "${red}$line${reset}"
  echo "${yellow}$1${reset}"
  echo "${red}$line${reset}"
}

function install_deb_apps() {
  header "Installing local DEB apps"
  sudo apt -y install ~/Linux/apps/bat*.deb
  sudo apt -y install ~/Linux/apps/lsd*.deb
  sudo cp ~/Linux/apps/whichSystem.py /usr/bin/
  sudo chmod +x /usr/bin/whichSystem.py
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
  sudo cp -r ./zsh/* /usr/share/zsh/
  sudo usermod --shell /usr/bin/zsh $USER
  sudo usermod --shell /usr/bin/zsh root
  header "Done"
  sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes/chucknorris.dat
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

function install_kitty() {
  header "Kitty"
  sudo apt -y install kitty
  sudo cp ~/Linux/apps/kitty/* ~/.config/kitty/
}

function install_sublime() {
  header "Sublime"
  sudo apt -y install sublime-text
}

#------------
# Installers
#------------

# Install requirements
header "Adding Keys"
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add
echo "Sublime key added"
echo ""

header "Adding sources"
sudo cp ~/Linux/apps/sources/* /etc/apt/sources.list.d/
echo "Sources added to sources.list.d"
echo ""
echo ""

header "Installing requirements"
sudo apt -y install git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu snapd default-mysql-client imagemagick
sudo apt -y install acl fortune cowsay locate curl 
sudo apt -y install software-properties-common
sudo apt -y install docker.io docker docker-compose docker-clean
echo ""
echo ""

# Update and upgrade
header "Updating and Upgrading the system"
sudo apt update
sudo apt -y upgrade
sudo apt -y autoremove || sudo apt --fix-broken install && sudo apt -y autoremove

# Install Sublime and configure
install_sublime

# Install Kitty and configure
install_kitty

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
sudo cp ~/Linux/apps/kitty/* ~/.config/kitty/

clear
header "Script by: Carlos Perez Andrade"
echo
fortune | cowsay 2>/dev/null