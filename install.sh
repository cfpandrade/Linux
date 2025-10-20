#!/bin/bash
set -euo pipefail

# Clear screen
clear

# Colours
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
reset=$(tput sgr0)

# Logging setup
LOGFILE="${LOGFILE:-$HOME/linux-install.log}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log(){
  local level="$1"; shift
  local msg="$*"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $msg" | tee -a "$LOGFILE"
}

log_info(){ log "INFO" "$@"; }
log_warn(){ log "WARN" "$@"; }
log_error(){ log "ERROR" "$@"; }
log_success(){ log "SUCCESS" "$@"; }

header(){
  local line; line=$(printf '%*s' "${#1}" '' | tr ' ' '=')
  printf "\n${red}%s${reset}\n${yellow}%s${reset}\n${red}%s${reset}\n" "$line" "$1" "$line"
  log_info "$1"
}

# Error handler
error_exit(){
  log_error "$1"
  echo "${red}ERROR: $1${reset}" >&2
  exit 1
}

# Validate file exists
validate_file(){
  local file="$1"
  [[ -f "$file" ]] || error_exit "Required file not found: $file"
}

# Validate directory exists
validate_dir(){
  local dir="$1"
  [[ -d "$dir" ]] || error_exit "Required directory not found: $dir"
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
  [[ $PM == apt* ]] || { log_info "Skipping DEB apps (not an apt-based system)"; return 0; }
  header "Installing local DEB apps"

  # Validate required files exist
  validate_file "./apps/whichSystem.py"

  # Install DEB packages if they exist
  local deb_files=(./apps/bat*.deb ./apps/lsd*.deb)
  for deb in "${deb_files[@]}"; do
    if [[ -f "$deb" ]]; then
      log_info "Installing $deb"
      sudo $PM install "$deb" || log_warn "Failed to install $deb"
    else
      log_warn "DEB file not found: $deb"
    fi
  done

  # Install whichSystem.py
  if [[ ! -f /usr/bin/whichSystem.py ]] || ! cmp -s ./apps/whichSystem.py /usr/bin/whichSystem.py; then
    log_info "Installing whichSystem.py"
    sudo cp ./apps/whichSystem.py /usr/bin/
    sudo chmod +x /usr/bin/whichSystem.py
    log_success "whichSystem.py installed"
  else
    log_info "whichSystem.py already up to date"
  fi
}

install_fonts(){
  header "Installing fonts"

  # Validate fonts directory exists
  validate_dir "./fonts"

  # Create fonts directory if it doesn't exist
  if [[ ! -d ~/.fonts ]]; then
    log_info "Creating ~/.fonts directory"
    mkdir -p ~/.fonts
  fi

  # Copy fonts
  log_info "Copying fonts to ~/.fonts"
  cp -r ./fonts/* ~/.fonts/ || log_warn "Some fonts may not have been copied"

  # Rebuild font cache
  log_info "Rebuilding font cache"
  fc-cache -f -v >> "$LOGFILE" 2>&1 || log_warn "Font cache rebuild had issues"
  log_success "Fonts installed successfully"
}

install_zsh(){
  header "ZSH Configuration"

  # Validate required files
  validate_file ".zshrc"
  validate_dir "./zsh"

  # Backup existing .zshrc if present
  if [[ -f ~/.zshrc ]]; then
    log_info "Backing up existing .zshrc to ~/.zshrc.backup"
    cp ~/.zshrc ~/.zshrc.backup
  fi

  # Copy configuration
  log_info "Installing .zshrc"
  cp .zshrc ~ || error_exit "Failed to copy .zshrc"

  log_info "Installing zsh plugins"
  sudo cp -r ./zsh/* /usr/share/zsh/ || error_exit "Failed to copy zsh plugins"

  # Set zsh as default shell
  if [[ -x /usr/bin/zsh ]]; then
    if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
      log_info "Setting zsh as default shell for $USER"
      sudo usermod --shell /usr/bin/zsh "$USER" || log_warn "Failed to set zsh for $USER"
    else
      log_info "zsh already set as default shell for $USER"
    fi

    log_info "Setting zsh as default shell for root"
    sudo usermod --shell /usr/bin/zsh root || log_warn "Failed to set zsh for root"
  else
    log_error "zsh binary not found at /usr/bin/zsh"
  fi

  # Fix permissions for chuck norris fortunes
  if [[ -f /usr/share/zsh/plugins/zsh-chuck/fortunes/chucknorris.dat ]]; then
    sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes/chucknorris.dat
    log_success "ZSH configuration completed"
  else
    log_warn "Chuck Norris fortunes file not found"
  fi
}

install_powerlevel10k(){
  header "PowerLevel10k"

  local p10k_dir="/usr/bin/powerlevel10k"

  if [[ -d "$p10k_dir" ]]; then
    log_info "PowerLevel10k already installed, updating..."
    (cd "$p10k_dir" && sudo git pull) || log_warn "Failed to update PowerLevel10k"
  else
    log_info "Cloning PowerLevel10k repository"
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" || error_exit "Failed to clone PowerLevel10k"
    log_success "PowerLevel10k installed successfully"
  fi
}

install_fzf(){
  header "FZF"

  local fzf_dir="$HOME/.fzf"

  if [[ -d "$fzf_dir" ]]; then
    log_info "FZF already installed, updating..."
    (cd "$fzf_dir" && git pull) || log_warn "Failed to update FZF"
  else
    log_info "Cloning FZF repository"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir" || error_exit "Failed to clone FZF"
  fi

  log_info "Installing FZF"
  "$fzf_dir/install" --key-bindings --completion --no-update-rc || log_warn "FZF install script had issues"

  # Fix permissions for chuck norris fortunes
  if [[ -d /usr/share/zsh/plugins/zsh-chuck/fortunes ]]; then
    sudo chmod 777 /usr/share/zsh/plugins/zsh-chuck/fortunes
    log_success "FZF installed successfully"
  else
    log_warn "Chuck Norris fortunes directory not found"
  fi
}

install_kitty(){
  header "Kitty"

  # Install kitty package
  log_info "Installing Kitty terminal emulator"
  sudo $PM install kitty || log_warn "Failed to install kitty"

  # Create config directory
  local kitty_config="$HOME/.config/kitty"
  if [[ ! -d "$kitty_config" ]]; then
    log_info "Creating kitty config directory"
    mkdir -p "$kitty_config"
  fi

  # Copy configuration files
  if [[ -d ./apps/kitty ]]; then
    log_info "Copying kitty configuration files"
    cp ./apps/kitty/* "$kitty_config/" || log_warn "Failed to copy some kitty config files"
    log_success "Kitty installed and configured"
  else
    log_warn "Kitty config directory not found in ./apps/kitty"
  fi
}

install_core_packages(){
  header "Installing requirements"

  log_info "Installing core packages"
  sudo $PM install git vim xcb fonts-powerline tmux zsh-autosuggestions mawk sed htop neovim ncdu imagemagick mariadb-client \
                   acl fortune cowsay locate curl software-properties-common docker.io docker-compose docker-clean \
                   duf ripgrep iotop-c dstat progress termshark ipcalc unp taskwarrior asciinema || {
    log_warn "Some packages may not have been installed"
  }

  # Install snapd if not present
  if ! command -v snap >/dev/null 2>&1; then
    log_info "Installing snapd"
    sudo $PM install snapd || log_warn "Failed to install snapd"
  else
    log_info "snapd already installed"
  fi

  # Install lazydocker
  if ! command -v lazydocker >/dev/null 2>&1; then
    log_info "Installing lazydocker"
    curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash || log_warn "Failed to install lazydocker"
  else
    log_info "lazydocker already installed"
  fi

  log_success "Core packages installation completed"
}

update_system(){
  header "Updating and Upgrading the system"

  log_info "Updating package lists and upgrading system"
  case "$PM" in
    apt*)
      sudo apt update || log_warn "apt update failed"
      sudo apt -y upgrade || log_warn "apt upgrade failed"
      sudo apt -y autoremove || log_warn "apt autoremove failed"
      ;;
    dnf*)
      sudo dnf -y upgrade --refresh || log_warn "dnf upgrade failed"
      sudo dnf -y autoremove || log_warn "dnf autoremove failed"
      ;;
    yum*)
      sudo yum -y update || log_warn "yum update failed"
      sudo yum -y autoremove || log_warn "yum autoremove failed"
      ;;
  esac

  log_success "System update completed"
}

install_snap_apps(){
  if ! command -v snap >/dev/null 2>&1; then
    log_info "Snap not available, skipping snap apps installation"
    return 0
  fi

  header "SNAP apps"
  export PATH=/snap/bin:$PATH

  # Validate snap packages file exists
  if [[ ! -f snap_packages.txt ]]; then
    log_warn "snap_packages.txt not found, skipping snap apps installation"
    return 0
  fi

  log_info "Reading snap packages from snap_packages.txt"
  mapfile -t snaplist < snap_packages.txt

  for pkg in "${snaplist[@]}"; do
    # Skip empty lines and comments
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

    if snap list "$pkg" >/dev/null 2>&1; then
      log_info "Snap package '$pkg' already installed"
    else
      log_info "Installing snap package: $pkg"
      if sudo snap install --classic "$pkg" 2>/dev/null; then
        log_success "Installed $pkg with --classic"
      elif sudo snap install "$pkg" 2>/dev/null; then
        log_success "Installed $pkg"
      else
        log_warn "Failed to install snap package: $pkg"
      fi
    fi
  done

  log_success "Snap apps installation completed"
}

main(){
  # Print start message
  echo "${green}========================================${reset}"
  echo "${green}Linux Installation Script${reset}"
  echo "${green}By: Carlos Perez Andrade${reset}"
  echo "${green}========================================${reset}"
  echo "${yellow}Log file: $LOGFILE${reset}"
  echo ""
  log_info "Installation script started"
  log_info "Running from: $SCRIPT_DIR"
  log_info "Package manager: $PM"

  # Load configuration if exists
  if [[ -f "$SCRIPT_DIR/install.conf" ]]; then
    log_info "Loading configuration from install.conf"
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/install.conf"
  fi

  # Run installation steps (can be controlled by config)
  ${INSTALL_CORE_PACKAGES:-true} && install_core_packages
  ${UPDATE_SYSTEM:-true} && update_system
  ${INSTALL_KITTY:-true} && install_kitty
  ${INSTALL_DEB_APPS:-true} && install_deb_apps
  ${INSTALL_FONTS:-true} && install_fonts
  ${INSTALL_ZSH:-true} && install_zsh
  ${INSTALL_POWERLEVEL10K:-true} && install_powerlevel10k
  ${INSTALL_FZF:-true} && install_fzf
  ${INSTALL_SNAP_APPS:-true} && install_snap_apps

  # Final message
  clear
  header "Installation Complete!"
  echo "${green}Script by: Carlos Perez Andrade${reset}"
  echo "${yellow}Log file: $LOGFILE${reset}"
  echo ""
  log_success "Installation script completed successfully"

  # Show fortune if available
  if command -v fortune >/dev/null 2>&1 && command -v cowsay >/dev/null 2>&1; then
    fortune | cowsay 2>/dev/null
  fi
}

main "$@"
