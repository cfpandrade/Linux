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

function check_homebrew() {
  if ! command -v brew &> /dev/null; then
    header "Instalando Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configurar Homebrew en el PATH
    if [[ $(uname -m) == 'arm64' ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
}

function install_cli_apps() {
  header "Installing CLI tools"
  brew install bat
  brew install lsd
  brew install git
  brew install vim
  brew install neovim
  brew install tmux
  brew install htop
  brew install ncdu
  brew install curl
  brew install wget
  brew install fortune
  brew install cowsay
  brew install mysql-client
}

function install_fonts() {
  header "Installing fonts"

  # Nerd Fonts
  brew tap homebrew/cask-fonts
  brew install --cask font-meslo-lg-nerd-font
  brew install --cask font-hack-nerd-font
  brew install --cask font-fira-code-nerd-font

  # Copy local fonts if exist
  if [ -d "./fonts" ]; then
    cp -r ./fonts/* ~/Library/Fonts/
  fi
}

function install_zsh() {
  header "ZSH Configuration"

  # Copy .zshrc if exists
  if [ -f ".zshrc" ]; then
    cp .zshrc ~
  fi

  # Install Oh My Zsh if not installed
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Install zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true

  # Install zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

  # Change shell to zsh
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
  fi

  header "Done"
}

function install_powerlevel10k() {
  header "PowerLevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null || true
}

function install_fzf() {
  header "FZF"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
  ~/.fzf/install --key-bindings --completion --all --no-bash
}

function install_kitty() {
  header "Kitty"
  brew install --cask kitty

  # Copy kitty config if exists
  if [ -d "./apps/kitty" ]; then
    mkdir -p ~/.config/kitty
    cp ./apps/kitty/* ~/.config/kitty/
  fi
}

function install_sublime() {
  header "Sublime"
  brew install --cask sublime-text
}

function install_docker() {
  header "Docker"
  brew install docker
  brew install docker-compose
  brew install --cask docker
}

#------------
# Installers
#------------

# Check/Install Homebrew
header "Checking Homebrew"
check_homebrew
echo ""
echo ""

# Update Homebrew
header "Updating Homebrew"
brew update
brew upgrade
echo ""
echo ""

# Install requirements
header "Installing requirements"
brew install fonts-powerline 2>/dev/null || true
brew install imagemagick
echo ""
echo ""

# Install Docker
install_docker

# Install Sublime and configure
install_sublime

# Install Kitty and configure
install_kitty

# Install CLI apps
install_cli_apps

# Install fonts
install_fonts

# Install ZSH
install_zsh

# Install PowerLevel10k
install_powerlevel10k

# Install FZF
install_fzf

# Install GUI apps
header "Installing GUI Applications"
brew install --cask brave-browser
brew install --cask bitwarden
brew install --cask spotify
brew install --cask telegram
brew install --cask vlc
brew install --cask rectangle
brew install --cask alt-tab

# Install development tools
header "Installing Development Tools"
brew install node
brew install python@3.11
brew install kubectl
brew install --cask postman
brew install --cask powershell

# Cleanup
header "Cleaning up"
brew cleanup
brew autoremove

clear
header "Script by: Carlos Perez Andrade"
echo
fortune | cowsay 2>/dev/null
