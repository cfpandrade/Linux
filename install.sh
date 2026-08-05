#!/usr/bin/env bash
#
# Linux workstation bootstrap
#   Usage:  ./install.sh                 # run everything
#           ./install.sh zsh kitty llm   # run only some modules
#           ./install.sh --list          # show available modules
#           ./install.sh --dry-run       # print what would run
#
# Do NOT run with sudo: the script needs your real $HOME and asks for
# sudo only where it is actually required.

set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR" || exit 1

DRY_RUN=0
FAILURES=()
SKIPPED=()

#------------
# Output helpers
#------------

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3)
  blue=$(tput setaf 4); reset=$(tput sgr0)
else
  red=""; green=""; yellow=""; blue=""; reset=""
fi

header() {
  local line
  line=$(printf '%*s' "${#1}" '' | tr ' ' '=')
  printf '\n%s\n%s\n%s\n' "${red}${line}${reset}" "${yellow}${1}${reset}" "${red}${line}${reset}"
}

info() { printf '  %s\n' "$1"; }
ok()   { printf '  %s%s%s\n' "$green" "$1" "$reset"; }
warn() { printf '  %s%s%s\n' "$yellow" "$1" "$reset"; }
err()  { printf '  %s%s%s\n' "$red" "$1" "$reset"; FAILURES+=("$1"); }

run() {
  if (( DRY_RUN )); then
    printf '  %s[dry-run]%s %s\n' "$blue" "$reset" "$*"
    return 0
  fi
  "$@"
}

have() { command -v "$1" >/dev/null 2>&1; }

#------------
# Environment detection
#------------

detect_os() {
  [[ -r /etc/os-release ]] || { err "Cannot detect OS (/etc/os-release missing)"; exit 1; }
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_LIKE="${ID_LIKE:-}"
  OS_NAME="${PRETTY_NAME:-$OS_ID}"

  case "$OS_ID $OS_LIKE" in
    *ubuntu*|*debian*) PKG=apt ;;
    *fedora*)          PKG=dnf ;;
    *rhel*|*centos*)   PKG=$(have dnf && echo dnf || echo yum) ;;
    *arch*)            PKG=pacman ;;
    *) err "Unsupported distribution: $OS_NAME"; exit 1 ;;
  esac
}

require_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    err "Run this script as your normal user (it calls sudo when needed), not with sudo."
    exit 1
  fi
}

keep_sudo_alive() {
  (( DRY_RUN )) && return 0
  if ! sudo -n true 2>/dev/null; then
    if [[ ! -t 0 ]]; then
      warn "no terminal to authenticate sudo; steps needing root will fail"
      return 0
    fi
    sudo -v || { err "sudo is required"; exit 1; }
  fi
  # Refresh the sudo timestamp in the background until the script exits.
  while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
}

#------------
# Package helpers
#------------

pkg_update() {
  case "$PKG" in
    apt)    run sudo apt-get update -qq ;;
    dnf)    run sudo dnf -y makecache ;;
    yum)    run sudo yum -y makecache ;;
    pacman) run sudo pacman -Sy --noconfirm ;;
  esac
}

pkg_installed() {
  case "$PKG" in
    apt)    dpkg -s "$1" >/dev/null 2>&1 ;;
    dnf|yum) rpm -q "$1" >/dev/null 2>&1 ;;
    pacman) pacman -Qi "$1" >/dev/null 2>&1 ;;
  esac
}

# Install packages one by one so a single unavailable name does not abort the
# whole batch (package names drift a lot between releases).
pkg_install() {
  local pkg missing=()
  for pkg in "$@"; do
    pkg_installed "$pkg" && continue
    missing+=("$pkg")
  done
  [[ ${#missing[@]} -eq 0 ]] && { info "all packages already present"; return 0; }

  for pkg in "${missing[@]}"; do
    local cmd
    case "$PKG" in
      apt)    cmd=(sudo apt-get install -y -qq "$pkg") ;;
      dnf)    cmd=(sudo dnf -y install "$pkg") ;;
      yum)    cmd=(sudo yum -y install "$pkg") ;;
      pacman) cmd=(sudo pacman -S --noconfirm --needed "$pkg") ;;
    esac
    if (( DRY_RUN )); then
      run "${cmd[@]}"
    elif "${cmd[@]}" >/dev/null 2>&1; then
      ok "installed $pkg"
    else
      warn "not available: $pkg"
      SKIPPED+=("$pkg")
    fi
  done
}

#------------
# Modules
#------------

# --- system ---------------------------------------------------------------
APT_PKGS=(
  # shell + editors
  zsh zsh-autosuggestions zsh-syntax-highlighting vim neovim tmux
  # core CLI
  git curl wget jq unzip unp ca-certificates gnupg lsof vim-common acl
  ripgrep fd-find bat lsd duf ncdu htop plocate progress dstat
  ipcalc taskwarrior asciinema imagemagick mariadb-client xclip boxes
  # modern shell workflow
  fzf zoxide atuin git-delta gh pipx
  # desktop / fonts / hardware
  fonts-powerline fontconfig fwupd ratbagd piper
  # fun
  fortune-mod cowsay
  # containers: distro docker + compose v2 (see the optional `docker` module
  # if you ever need the upstream Docker CE build)
  docker.io docker-compose-v2 docker-buildx
  # build deps for anything installed from source
  build-essential python3-pip python3-venv
  # extras that may or may not exist depending on the release
  iotop-c termshark software-properties-common
)

DNF_PKGS=(
  zsh vim neovim tmux git curl wget jq unzip gnupg2 lsof acl
  ripgrep fd-find bat lsd duf ncdu htop mlocate progress
  ipcalc task asciinema ImageMagick mariadb xclip boxes
  fzf zoxide atuin git-delta gh pipx
  powerline-fonts fontconfig fwupd ratbagd piper fortune-mod cowsay
  python3-pip
)

PACMAN_PKGS=(
  zsh zsh-autosuggestions zsh-syntax-highlighting vim neovim tmux
  git curl wget jq unzip gnupg lsof acl ripgrep fd bat lsd duf ncdu htop
  plocate progress ipcalc task asciinema imagemagick mariadb-clients xclip boxes
  fzf zoxide atuin git-delta github-cli python-pipx
  powerline-fonts fontconfig fwupd libratbag piper fortune-mod cowsay python-pip
)

module_system() {
  header "Base packages ($OS_NAME)"
  pkg_update
  case "$PKG" in
    apt)     pkg_install "${APT_PKGS[@]}" ;;
    dnf|yum) pkg_install "${DNF_PKGS[@]}" ;;
    pacman)  pkg_install "${PACMAN_PKGS[@]}" ;;
  esac

  # Debian/Ubuntu ship these under different binary names.
  mkdir -p "$HOME/.local/bin"
  have batcat && [[ ! -e "$HOME/.local/bin/bat" ]] && run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  have fdfind && [[ ! -e "$HOME/.local/bin/fd" ]]  && run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"

  if [[ -f ./apps/whichSystem.py ]]; then
    run sudo install -m 755 ./apps/whichSystem.py /usr/bin/whichSystem.py
    ok "whichSystem.py installed"
  fi

  if [[ "$PKG" == apt ]] && pkg_installed docker-compose; then
    warn "docker-compose v1 (python) is installed and unmaintained;"
    warn "use 'docker compose' and remove it with: sudo apt remove docker-compose"
  fi
  module_docker_group
}

# --- docker ---------------------------------------------------------------
# NOT part of the default run: switching from the distro packages to Docker CE
# makes apt remove docker.io/containerd, which stops every running container.
# Only worth it if the distro version is actually behind — recent Ubuntu ships
# an up-to-date docker.io. Run it explicitly: ./install.sh docker
module_docker() {
  header "Docker"

  if pkg_installed docker.io; then
    local running
    running=$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')
    warn "docker.io $(dpkg-query -W -f='${Version}' docker.io 2>/dev/null) is installed."
    warn "Installing Docker CE will REMOVE it (and containerd), stopping any container."
    [[ -n "$running" ]] && warn "Currently running: $running"
    if [[ -t 0 ]] && (( ! DRY_RUN )); then
      read -r -p "  Replace docker.io with Docker CE? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] || { info "keeping docker.io"; module_docker_compose_only; return; }
    else
      info "non-interactive: keeping docker.io"
      module_docker_compose_only
      return
    fi
  fi

  if [[ "$PKG" != apt ]]; then
    pkg_install docker docker-compose
  else
    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
      run sudo install -m 0755 -d /etc/apt/keyrings
      (( DRY_RUN )) || sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
      run sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
      local codename
      codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
      (( DRY_RUN )) || echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      run sudo apt-get update -qq
    fi
    pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # Fall back to the distro packages if the upstream repo has no build yet
    have docker || pkg_install docker.io docker-compose-v2
  fi

  module_docker_group
}

# Keep the distro docker but make sure compose v2 is the one in use: the old
# python `docker-compose` (v1) is unmaintained and `docker compose` needs the
# plugin package.
module_docker_compose_only() {
  if [[ "$PKG" == apt ]]; then
    pkg_install docker-compose-v2 docker-buildx
    if pkg_installed docker-compose; then
      warn "docker-compose v1 (python) is installed and unmaintained."
      warn "Remove it once your compose files work with 'docker compose': sudo apt remove docker-compose"
    fi
  fi
  module_docker_group
}

module_docker_group() {
  if have docker && ! id -nG "$USER" | grep -qw docker; then
    run sudo usermod -aG docker "$USER"
    warn "added $USER to the docker group (log out and back in to use it)"
  fi
}

# --- git ------------------------------------------------------------------
module_git() {
  header "Git configuration"
  if have delta || have git-delta; then
    run git config --global core.pager delta
    run git config --global interactive.diffFilter 'delta --color-only'
    run git config --global delta.navigate true
    run git config --global delta.line-numbers true
    run git config --global delta.side-by-side false
    run git config --global merge.conflictstyle zdiff3
    run git config --global diff.colorMoved default
    ok "delta configured as git pager"
  else
    warn "git-delta not installed, skipping pager setup"
  fi
  run git config --global pull.ff only
  run git config --global init.defaultBranch main
  run git config --global rebase.autoStash true

  if have gh && ! gh auth status >/dev/null 2>&1; then
    warn "gh installed but not authenticated — run: gh auth login"
  fi
}

# --- upgrade --------------------------------------------------------------
module_upgrade() {
  header "Updating and upgrading the system"
  case "$PKG" in
    apt)     run sudo apt-get update -qq && run sudo apt-get -y full-upgrade
             run sudo apt-get -y --fix-broken install
             run sudo apt-get -y autoremove ;;
    dnf)     run sudo dnf -y upgrade --refresh && run sudo dnf -y autoremove ;;
    yum)     run sudo yum -y update && run sudo yum -y autoremove ;;
    pacman)  run sudo pacman -Syu --noconfirm ;;
  esac
}

# --- fonts ----------------------------------------------------------------
module_fonts() {
  header "Nerd Fonts"
  local dest="$HOME/.local/share/fonts"
  run mkdir -p "$dest"

  # Older versions of this script used ~/.fonts. Migrate instead of installing
  # a second copy, or every font picker shows each family twice.
  if [[ -d "$HOME/.fonts" ]]; then
    run mv "$HOME/.fonts"/* "$dest"/ 2>/dev/null
    rmdir "$HOME/.fonts" 2>/dev/null && ok "migrated ~/.fonts to $dest"
  fi

  run cp -r ./fonts/. "$dest"/
  run fc-cache -f >/dev/null
  ok "fonts installed into $dest"
}

# --- zsh ------------------------------------------------------------------
module_zsh() {
  header "ZSH configuration"

  if [[ -f "$HOME/.zshrc" ]] && ! diff -q ./.zshrc "$HOME/.zshrc" >/dev/null 2>&1; then
    local backup
    backup="$HOME/.zshrc.bak.$(date +%F-%H%M%S)"
    run cp "$HOME/.zshrc" "$backup"
    warn "existing ~/.zshrc backed up to $backup"
  fi
  run cp ./.zshrc "$HOME/.zshrc"
  [[ -f ./.p10k.zsh ]] && run cp ./.p10k.zsh "$HOME/.p10k.zsh"
  [[ -f ./.tmux.conf ]] && run cp ./.tmux.conf "$HOME/.tmux.conf"
  [[ -f ./.tmux.conf.local ]] && run cp ./.tmux.conf.local "$HOME/.tmux.conf.local"

  # Shell functions live outside .zshrc and are sourced from there
  run mkdir -p "$HOME/.config/zsh/functions"
  run cp ./zsh/functions/*.zsh "$HOME/.config/zsh/functions/"
  ok "shell functions installed into ~/.config/zsh/functions"

  run sudo mkdir -p /usr/share/zsh/plugins
  run sudo cp -r ./zsh/plugins/. /usr/share/zsh/plugins/
  # The chuck plugin writes to its own fortune dir; make it group writable
  # instead of the old chmod 777.
  if [[ -d /usr/share/zsh/plugins/zsh-chuck/fortunes ]]; then
    run sudo chgrp -R "$(id -gn)" /usr/share/zsh/plugins/zsh-chuck/fortunes
    run sudo chmod -R g+w /usr/share/zsh/plugins/zsh-chuck/fortunes
  fi

  local zsh_bin; zsh_bin=$(command -v zsh)
  if [[ -n "$zsh_bin" && "$SHELL" != "$zsh_bin" ]]; then
    run sudo chsh -s "$zsh_bin" "$USER"
    ok "default shell set to $zsh_bin"
  else
    info "default shell already zsh"
  fi
}

# --- powerlevel10k --------------------------------------------------------
module_p10k() {
  header "Powerlevel10k"
  local dir=/usr/share/powerlevel10k
  local legacy=/usr/bin/powerlevel10k

  # Older versions of this script cloned into /usr/bin/powerlevel10k. Move that
  # checkout instead of cloning a second copy, and leave a symlink behind so
  # any config still pointing at the old path keeps working.
  if [[ -d "$legacy/.git" && ! -L "$legacy" && ! -d "$dir" ]]; then
    run sudo mv "$legacy" "$dir"
    run sudo ln -s "$dir" "$legacy"
    ok "moved the existing checkout from $legacy to $dir (symlinked back)"
  fi

  if [[ -d "$dir/.git" ]]; then
    run sudo git -C "$dir" pull --ff-only --quiet && ok "powerlevel10k updated"
  else
    run sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dir" \
      && ok "powerlevel10k installed in $dir"
  fi

  [[ -e "$legacy" ]] || run sudo ln -s "$dir" "$legacy"
}

# --- shell tools ----------------------------------------------------------
# fzf >= 0.48 ships its own shell integration (`fzf --zsh`), so the git clone in
# ~/.fzf is no longer needed. zoxide and atuin are wired up from .zshrc too.
module_shelltools() {
  header "Shell tools (fzf / zoxide / atuin)"
  pkg_install fzf zoxide atuin

  # Retire the old ~/.fzf checkout: its binary shadows the packaged one and it
  # predates the built-in `fzf --zsh` integration.
  if [[ -d "$HOME/.fzf" ]] && command -v /usr/bin/fzf >/dev/null 2>&1 \
     && /usr/bin/fzf --zsh >/dev/null 2>&1; then
    run /bin/rm -rf "$HOME/.fzf" "$HOME/.fzf.zsh"
    ok "removed the legacy ~/.fzf checkout (the packaged fzf supersedes it)"
    hash -r 2>/dev/null
  fi

  if have fzf; then
    if fzf --zsh >/dev/null 2>&1; then
      ok "fzf $(fzf --version | awk '{print $1}') with built-in shell integration"
    else
      warn "fzf $(fzf --version | awk '{print $1}') is older than 0.48; .zshrc falls back to ~/.fzf.zsh"
    fi
  fi

  have zoxide && ok "zoxide ready (z <dir>, zi to pick interactively)"
  if have atuin; then
    ok "atuin ready — run 'atuin register' or 'atuin login' to sync history"
  fi
}

# --- kitty ----------------------------------------------------------------
# The distro package lags several versions behind; use the upstream installer,
# same as the `actualizar` function does.
module_kitty() {
  header "Kitty"
  local installed="" latest newest
  have kitty && installed=$(kitty --version | awk '{print $2}')
  latest=$(curl -fsSL https://api.github.com/repos/kovidgoyal/kitty/releases/latest \
           | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -n1)

  if [[ -z "$latest" ]]; then
    warn "could not query the latest kitty release"
  elif [[ -z "$installed" ]]; then
    info "installing kitty v$latest"
    (( DRY_RUN )) || curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  else
    newest=$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -n1)
    if [[ "$newest" == "$latest" && "$installed" != "$latest" ]]; then
      info "upgrading kitty v$installed -> v$latest"
      (( DRY_RUN )) || curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    else
      ok "kitty v$installed is current"
    fi
  fi

  run mkdir -p "$HOME/.config/kitty"

  # Earlier versions of this script copied the config with sudo, which left
  # root-owned files that a normal `cp` cannot overwrite.
  if [[ -n "$(find "$HOME/.config/kitty" ! -user "$USER" -print -quit 2>/dev/null)" ]]; then
    run sudo chown -R "$USER:$(id -gn)" "$HOME/.config/kitty"
    ok "fixed root-owned files left by an older install"
  fi

  if run cp -r ./apps/kitty/. "$HOME/.config/kitty"/; then
    ok "kitty config copied"
  else
    err "could not copy the kitty config into ~/.config/kitty"
  fi

  # Desktop entry + icon for the upstream install
  if [[ -d "$HOME/.local/kitty.app" ]]; then
    run mkdir -p "$HOME/.local/share/applications"
    run ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
    run ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten"
  fi
}

# --- default terminal -----------------------------------------------------
# Making kitty *the* terminal takes four different mechanisms, because every
# layer of the desktop stack answers the question differently.
module_terminal() {
  header "Default terminal"

  local kitty_bin desktop_dir="$HOME/.local/share/applications"
  kitty_bin=$(command -v kitty)
  if [[ -z "$kitty_bin" ]]; then
    err "kitty is not installed; run ./install.sh kitty first"
    return
  fi

  # 1. A .desktop entry the rest of the stack can point at.
  run mkdir -p "$desktop_dir"
  if [[ ! -f "$desktop_dir/kitty.desktop" ]]; then
    local app_dir="$HOME/.local/kitty.app"
    if [[ -f "$app_dir/share/applications/kitty.desktop" ]]; then
      (( DRY_RUN )) || sed \
        -e "s|Icon=kitty|Icon=$app_dir/share/icons/hicolor/256x256/apps/kitty.png|" \
        -e "s|^Exec=kitty|Exec=$app_dir/bin/kitty|" \
        -e "s|^TryExec=kitty|TryExec=$app_dir/bin/kitty|" \
        "$app_dir/share/applications/kitty.desktop" > "$desktop_dir/kitty.desktop"
      ok "created kitty.desktop"
    elif [[ -f /usr/share/applications/kitty.desktop ]]; then
      info "using the system-wide kitty.desktop"
    else
      err "no kitty.desktop found; cannot register kitty as the default terminal"
      return
    fi
  else
    info "kitty.desktop already present"
  fi

  # Without StartupWMClass the shell cannot match kitty's window to the entry
  # and shows a second, generic icon in the dock.
  if [[ -f "$desktop_dir/kitty.desktop" ]] && ! grep -q '^StartupWMClass=' "$desktop_dir/kitty.desktop"; then
    (( DRY_RUN )) || printf 'StartupWMClass=kitty\n' >> "$desktop_dir/kitty.desktop"
    ok "added StartupWMClass=kitty"
  fi

  have update-desktop-database && run update-desktop-database "$desktop_dir"

  # 2. xdg-terminal-exec (what GNOME 42+ and Nautilus actually use).
  # The first line wins, so check that one rather than mere presence.
  local list="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list"
  if [[ -f "$list" ]] && [[ "$(head -n1 "$list")" == "kitty.desktop" ]]; then
    info "kitty.desktop is already first in xdg-terminals.list"
  else
    (( DRY_RUN )) || { printf 'kitty.desktop\n'; [[ -f "$list" ]] && grep -vx 'kitty.desktop' "$list"; } > "$list.new" \
      && mv "$list.new" "$list"
    ok "kitty.desktop set as the preferred entry in $list"
  fi

  # 3. The x-scheme-handler/terminal association.
  have xdg-mime && run xdg-mime default kitty.desktop x-scheme-handler/terminal

  # 4. The legacy GNOME key, still read by a few applications.
  if have gsettings && gsettings writable org.gnome.desktop.default-applications.terminal exec >/dev/null 2>&1; then
    run gsettings set org.gnome.desktop.default-applications.terminal exec "$kitty_bin"
    run gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e'
    ok "GNOME default-applications.terminal points at $kitty_bin"
  fi

  # 5. Debian's alternatives system — only when kitty lives on a system path,
  #    otherwise root and other users would get a broken x-terminal-emulator.
  if [[ "$PKG" == apt ]] && have update-alternatives; then
    case "$kitty_bin" in
      /usr/bin/*|/usr/local/bin/*)
        run sudo update-alternatives --install /usr/bin/x-terminal-emulator \
            x-terminal-emulator "$kitty_bin" 60
        run sudo update-alternatives --set x-terminal-emulator "$kitty_bin"
        ok "x-terminal-emulator alternative set to $kitty_bin"
        ;;
      *)
        info "kitty is installed under \$HOME, skipping x-terminal-emulator (system-wide alternative)"
        ;;
    esac
  fi

  # 6. Ctrl+Alt+T. GNOME's built-in launch-terminal key is not always wired to
  #    xdg-terminal-exec, so bind it explicitly.
  if have gsettings; then
    local mk=org.gnome.settings-daemon.plugins.media-keys
    local kb_path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/
    local current
    current=$(gsettings get "$mk" custom-keybindings 2>/dev/null)
    if [[ "$current" != *"$kb_path"* ]]; then
      if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
        run gsettings set "$mk" custom-keybindings "['$kb_path']"
      else
        run gsettings set "$mk" custom-keybindings "${current%]}, '$kb_path']"
      fi
    fi
    run gsettings set "$mk.custom-keybinding:$kb_path" name 'kitty'
    run gsettings set "$mk.custom-keybinding:$kb_path" command "$kitty_bin"
    run gsettings set "$mk.custom-keybinding:$kb_path" binding '<Control><Alt>t'
    ok "Ctrl+Alt+T bound to kitty"
  fi

  warn "GNOME keeps its own 'preferred applications' cache — log out and back in if something still opens the old terminal"
}

# --- node + LLM CLIs ------------------------------------------------------
module_node() {
  header "Node.js"
  if have node; then
    ok "node $(node --version) already installed"
  else
    case "$PKG" in
      apt)     pkg_install nodejs npm ;;
      dnf|yum) pkg_install nodejs npm ;;
      pacman)  pkg_install nodejs npm ;;
    esac
  fi
}

module_llm() {
  header "LLM CLIs"
  module_node

  # Claude Code: official installer, self-updating, lands in ~/.local/bin
  if have claude; then
    ok "Claude Code $(claude --version 2>/dev/null | awk '{print $1}') already installed"
  else
    info "installing Claude Code"
    (( DRY_RUN )) || curl -fsSL https://claude.ai/install.sh | bash
  fi

  # Codex: npm global
  if have codex; then
    ok "Codex $(codex --version 2>/dev/null | awk '{print $NF}') already installed"
  elif have npm; then
    info "installing Codex"
    run sudo npm install -g @openai/codex
  else
    warn "npm missing, skipping Codex"
  fi
}

# --- lazydocker -----------------------------------------------------------
module_lazydocker() {
  header "lazydocker"
  if have lazydocker; then
    ok "lazydocker already installed"
  else
    (( DRY_RUN )) || curl -fsSL \
      https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  fi
}

# --- snap -----------------------------------------------------------------
SNAP_CLASSIC=(code sublime-text powershell waveterm)
SNAP_STRICT=(bitwarden brave dog kubectl mysql-shell onenote-desktop procs
             searchsploit slack spotify storage-explorer teams-for-linux
             telegram-desktop thunderbird vlc wps-office-multilang)

module_snap() {
  header "Snap applications"
  if ! have snap; then
    pkg_install snapd || { warn "snapd unavailable, skipping"; return; }
  fi
  export PATH=/snap/bin:$PATH

  local pkg flag
  for pkg in "${SNAP_CLASSIC[@]}" "${SNAP_STRICT[@]}"; do
    snap list "$pkg" >/dev/null 2>&1 && { info "$pkg present"; continue; }
    flag=""
    [[ " ${SNAP_CLASSIC[*]} " == *" $pkg "* ]] && flag="--classic"
    if (( DRY_RUN )); then
      run sudo snap install $flag "$pkg"
    elif sudo snap install $flag "$pkg" >/dev/null 2>&1; then
      ok "installed $pkg"
    else
      warn "failed: $pkg"
      SKIPPED+=("snap:$pkg")
    fi
  done
}

# --- flatpak --------------------------------------------------------------
module_flatpak() {
  header "Flatpak"
  have flatpak || pkg_install flatpak
  if have flatpak; then
    run flatpak remote-add --if-not-exists --user flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo && ok "flathub remote ready"
  fi
}

#------------
# Driver
#------------

# Modules that run when no argument is given. `docker` is deliberately left
# out: it is a disruptive migration, run it on purpose.
MODULES=(system upgrade git fonts zsh p10k shelltools kitty terminal llm lazydocker snap flatpak)
OPTIONAL_MODULES=(docker)

usage() {
  cat <<EOF
Usage: ./install.sh [--dry-run] [module ...]

Modules (all of them run when none is given):
  system      base packages for the detected distribution
  upgrade     full system update / upgrade / autoremove
  git         global git config (delta pager, sane defaults)
  fonts       Hack Nerd Fonts into ~/.local/share/fonts
  zsh         .zshrc, .p10k.zsh, tmux config, shell functions and zsh plugins
  p10k        Powerlevel10k theme
  shelltools  fzf, zoxide and atuin
  kitty       latest kitty from upstream + config
  terminal    make kitty the default terminal emulator
  llm         Node.js and the AI CLIs
  lazydocker  lazydocker
  snap        snap desktop applications
  flatpak     flatpak + flathub remote

Optional (never part of a full run, ask for it by name):
  docker      replace the distro docker with Docker CE from the upstream repo
              (removes docker.io/containerd and stops running containers)

Options:
  --dry-run   print the commands instead of running them
  --list      list module names
  -h, --help  this help
EOF
}

main() {
  local requested=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --list)    printf '%s\n' "${MODULES[@]}"
                 printf '%s (optional, not run by default)\n' "${OPTIONAL_MODULES[@]}"
                 exit 0 ;;
      -h|--help) usage; exit 0 ;;
      -*)        err "Unknown option: $1"; usage; exit 1 ;;
      *)         requested+=("$1") ;;
    esac
    shift
  done

  require_not_root
  detect_os
  keep_sudo_alive

  [[ ${#requested[@]} -eq 0 ]] && requested=("${MODULES[@]}")

  local m
  for m in "${requested[@]}"; do
    if [[ " ${MODULES[*]} ${OPTIONAL_MODULES[*]} " != *" $m "* ]]; then
      err "Unknown module: $m"
      continue
    fi
    "module_$m"
  done

  header "Summary"
  info "Distribution : $OS_NAME"
  info "Modules      : ${requested[*]}"
  if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    warn "Not available in the repos: ${SKIPPED[*]}"
  fi
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    printf '  %sErrors:%s\n' "$red" "$reset"
    printf '    - %s\n' "${FAILURES[@]}"
  else
    ok "Finished without errors"
  fi

  echo
  header "Script by: Carlos Perez Andrade"
  have fortune && have cowsay && fortune | cowsay
}

main "$@"
