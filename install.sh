#!/bin/bash

# Clear the screen
clear

# Colors
red=$(tput setaf 1)
#green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

# Functions
function header() {
  local line
  line=$(printf '%*s' "${#1}" '' | tr ' ' '=')
  echo ""
  echo "${red}$line${reset}"
  echo "${yellow}$1${reset}"
  echo "${red}$line${reset}"
}

function install_deb_apps() {
  header "Installing local DEB apps"
  sudo apt -y install ./apps/bat*.deb
  sudo apt -y install ./apps/lsd*.deb
  sudo cp ./apps/whichSystem.py /usr/bin/
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
  sudo usermod --shell /usr/bin/zsh "$USER"
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
  sudo cp ./apps/kitty/* ~/.config/kitty/
}

#------------
# Installers
#------------

# Install requirements
#header "Adding sources"
#sudo cp ./apps/sources/* /etc/apt/sources.list.d/
#echo "Sources added to sources.list.d"
echo ""
echo ""

header "Installing requirements"
sudo apt -y install git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu snapd imagemagick mariadb-client
sudo apt -y install acl fortune cowsay locate curl 
sudo apt -y install software-properties-common
sudo apt -y install docker.io docker-compose docker-clean
sudo apt -y install duf ripgrep iotop-c dstat progress termshark ipcalc unp taskwarrior asciinema
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
echo ""
echo ""

# Update and upgrade
header "Updating and Upgrading the system"
sudo apt update
sudo apt -y upgrade
sudo apt -y autoremove || sudo apt --fix-broken install && sudo apt -y autoremove

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
sudo snap install --classic waveterm
sudo snap install bitwarden
sudo snap install brave
sudo snap install code
sudo snap install dog
sudo snap install kubectl
sudo snap install mysql-shell
sudo snap install onenote-desktop
sudo snap install powershell
sudo snap install procs
sudo snap install searchsploit
sudo snap install slack
sudo snap install spotify
sudo snap install storage-explorer
sudo snap install --classic sublime-text
sudo snap install teams-for-linux
sudo snap install telegram-desktop
sudo snap install thunderbird
sudo snap install vlc
sudo snap install whatsie
sudo snap install wps-office-multilang
sudo cp ./apps/kitty/* ~/.config/kitty/

source ~/.zshrc

clear
header "Script by: Carlos Perez Andrade"
echo
fortune | cowsay 2>/dev/null
