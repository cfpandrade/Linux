#!/bin/bash

# Clear screen
clear

# Colours
red=$(tput setaf 1)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

header(){
  local line; line=$(printf '%*s' "${#1}" '' | tr ' ' '=')
  printf "\n${red}%s${reset}\n${yellow}%s${reset}\n${red}%s${reset}\n" "$line" "$1" "$line"
}

# Detect package manager
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian) PM="apt -y" ;;
    fedora)        PM="dnf -y" ;;
    centos|rhel)   PM="yum -y" ;;
    *) echo "Unsupported OS"; exit 1 ;;
  esac
else
  echo "Cannot detect OS"; exit 1
fi

install_deb_apps(){
  [[ $PM == apt* ]] || return
  header "Installing local DEB apps"
  sudo $PM install ./apps/bat*.deb ./apps/lsd*.deb
  sudo cp ./apps/whichSystem.py /usr/bin/
  sudo chmod +x /usr/bin/whichSystem.py
}

install_fonts(){
  header "Installing fonts"
  mkdir -p ~/.fonts
  cp -r ./fonts/* ~/.fonts/
  fc-cache -f -v
}

install_zsh(){
  header "ZSH Configuration"
  cp .zshrc ~
  sudo cp -r ./zsh/* /usr/share/zsh/
  sudo usermod --shell /usr/bin/zsh "$USER"
  sudo usermod --shell /usr/bin/zsh root
  sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes/chucknorris.dat
}

install_powerlevel10k(){
  header "PowerLevel10k"
  sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/bin/powerlevel10k
}

install_fzf(){
  header "FZF"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --key-bindings --completion --all
  sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes
}

install_kitty(){
  header "Kitty"
  sudo $PM install kitty
  mkdir -p ~/.config/kitty
  cp ./apps/kitty/* ~/.config/kitty/
}

install_core_packages(){
  header "Installing requirements"
  sudo $PM install git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu imagemagick mariadb-client \
                   acl fortune cowsay locate curl software-properties-common docker.io docker-compose docker-clean \
                   duf ripgrep iotop-c dstat progress termshark ipcalc procs unp taskwarrior asciinema
  command -v snap >/dev/null || sudo $PM install snapd
  curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
}

update_system(){
  header "Updating and Upgrading the system"
  case "$PM" in
    apt*) sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove ;;
    dnf*) sudo dnf -y upgrade --refresh && sudo dnf -y autoremove ;;
    yum*) sudo yum -y update && sudo yum -y autoremove ;;
  esac
}

install_snap_apps(){
  command -v snap >/dev/null || return
  header "SNAP apps"
  export PATH=/snap/bin:$PATH
  snaplist=(waveterm dog bitwarden brave code kubectl mysql-shell onenote-desktop powershell searchsploit slack spotify \
            storage-explorer teams-for-linux telegram-desktop thunderbird vlc whatsie wps-office-multilang sublime-text)
  for pkg in "${snaplist[@]}"; do
    sudo snap install --classic "$pkg" 2>/dev/null || sudo snap install "$pkg" 2>/dev/null
  done
}

main(){
  install_core_packages
  update_system
  install_kitty
  install_deb_apps
  install_fonts
  install_zsh
  install_powerlevel10k
  install_fzf
  install_snap_apps
  clear
  header "Script by: Carlos Perez Andrade"
  fortune | cowsay 2>/dev/null
}

main "$@"
