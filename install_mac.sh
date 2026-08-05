#!/usr/bin/env bash
#
# macOS workstation bootstrap — the Homebrew counterpart of install.sh
#   Usage:  ./install_mac.sh                # run everything
#           ./install_mac.sh zsh kitty llm  # run only some modules
#           ./install_mac.sh --list         # show available modules
#           ./install_mac.sh --dry-run      # print what would run
#
# Do NOT run with sudo: Homebrew refuses to work as root and the script needs
# your real $HOME.

set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR" || exit 1

DRY_RUN=0
FAILURES=()
SKIPPED=()
BREW_PREFIX=""

USER="${USER:-$(id -un)}"

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
# Environment
#------------

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || {
    err "This script is for macOS. On Linux use ./install.sh"
    exit 1
  }
}

require_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    err "Run this script as your normal user; Homebrew refuses to run as root."
    exit 1
  fi
}

ensure_brew() {
  if have brew; then
    BREW_PREFIX="$(brew --prefix)"
    return 0
  fi

  header "Homebrew"
  if ! xcode-select -p >/dev/null 2>&1; then
    info "installing the Command Line Tools first (a dialog may appear)"
    run xcode-select --install
    warn "finish the Command Line Tools installation, then run this script again"
    exit 1
  fi

  (( DRY_RUN )) || /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_PREFIX=/opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW_PREFIX=/usr/local
  else
    err "Homebrew installation failed"
    exit 1
  fi
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  ok "Homebrew installed in $BREW_PREFIX"
}

#------------
# Package helpers
#------------

brew_installed()      { brew list --formula --versions "$1" >/dev/null 2>&1; }
brew_cask_installed() { brew list --cask --versions "$1" >/dev/null 2>&1; }

brew_install() {
  local pkg
  for pkg in "$@"; do
    if brew_installed "$pkg"; then
      info "$pkg already installed"
      continue
    fi
    if (( DRY_RUN )); then
      run brew install "$pkg"
    elif brew install "$pkg" >/dev/null 2>&1; then
      ok "installed $pkg"
    else
      warn "could not install formula: $pkg"
      SKIPPED+=("$pkg")
    fi
  done
}

brew_install_cask() {
  local pkg
  for pkg in "$@"; do
    if brew_cask_installed "$pkg"; then
      info "$pkg already installed"
      continue
    fi
    if (( DRY_RUN )); then
      run brew install --cask "$pkg"
    elif brew install --cask "$pkg" >/dev/null 2>&1; then
      ok "installed $pkg"
    else
      warn "could not install cask: $pkg"
      SKIPPED+=("cask:$pkg")
    fi
  done
}

#------------
# Modules
#------------

# --- system ---------------------------------------------------------------
# coreutils/gnu-sed give the GNU behaviour the shell functions expect.
BREW_FORMULAE=(
  # shell
  zsh zsh-autosuggestions zsh-syntax-highlighting powerlevel10k
  # editors and multiplexers
  vim neovim tmux
  # core CLI
  git curl wget jq gnupg lsof coreutils gnu-sed findutils grep
  ripgrep fd bat lsd duf ncdu htop tree
  # modern shell workflow
  fzf zoxide atuin git-delta gh pipx duti
  # fun
  fortune cowsay
  # misc
  imagemagick mysql-client node kubectl
)

module_system() {
  header "Homebrew formulae"
  brew_install "${BREW_FORMULAE[@]}"
  run mkdir -p "$HOME/.local/bin"
}

# --- upgrade --------------------------------------------------------------
module_upgrade() {
  header "Updating Homebrew"
  run brew update
  run brew upgrade
  run brew cleanup -s
  run brew autoremove
}

# --- git ------------------------------------------------------------------
module_git() {
  header "Git configuration"
  if have delta; then
    run git config --global core.pager delta
    run git config --global interactive.diffFilter 'delta --color-only'
    run git config --global delta.navigate true
    run git config --global delta.line-numbers true
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

# --- fonts ----------------------------------------------------------------
# The homebrew/cask-fonts tap was merged into homebrew/cask in 2024; tapping it
# now fails, so install the casks directly.
module_fonts() {
  header "Fonts"
  brew_install_cask font-hack-nerd-font font-meslo-lg-nerd-font font-fira-code-nerd-font

  if [[ -d ./fonts ]]; then
    run mkdir -p "$HOME/Library/Fonts"
    run cp -r ./fonts/. "$HOME/Library/Fonts"/
    ok "repository fonts copied into ~/Library/Fonts"
  fi
}

# --- zsh ------------------------------------------------------------------
# No Oh My Zsh: the .zshrc in this repository loads Powerlevel10k and the
# plugins itself, so installing OMZ would only add an unused framework whose
# paths the .zshrc never looks at.
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

  # Same layout as on Linux, but under $HOME because /usr/share is read-only.
  run mkdir -p "$HOME/.config/zsh/functions"
  run cp ./zsh/functions/*.zsh "$HOME/.config/zsh/functions/"
  ok "shell functions installed into ~/.config/zsh/functions"

  # zsh-sudo and zsh-chuck have no Homebrew formula, so they come from here.
  # autosuggestions and syntax-highlighting come from the formulae instead.
  run mkdir -p "$HOME/.local/share/zsh/plugins"
  local p
  for p in zsh-sudo zsh-chuck; do
    [[ -d "./zsh/plugins/$p" ]] && run cp -r "./zsh/plugins/$p" "$HOME/.local/share/zsh/plugins/"
  done
  ok "bundled plugins installed into ~/.local/share/zsh/plugins"

  local zsh_bin="$BREW_PREFIX/bin/zsh"
  [[ -x "$zsh_bin" ]] || zsh_bin=/bin/zsh
  if [[ "${SHELL:-}" != "$zsh_bin" ]]; then
    if ! grep -qx "$zsh_bin" /etc/shells 2>/dev/null; then
      (( DRY_RUN )) || echo "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
    fi
    run chsh -s "$zsh_bin"
    ok "default shell set to $zsh_bin"
  else
    info "default shell already $zsh_bin"
  fi
}

# --- shell tools ----------------------------------------------------------
module_shelltools() {
  header "Shell tools (fzf / zoxide / atuin)"
  brew_install fzf zoxide atuin

  # Homebrew's fzf is always recent enough for the built-in integration, so the
  # ~/.fzf checkout the old script cloned is dead weight.
  if [[ -d "$HOME/.fzf" ]] && have fzf && fzf --zsh >/dev/null 2>&1; then
    run rm -rf "$HOME/.fzf" "$HOME/.fzf.zsh"
    ok "removed the legacy ~/.fzf checkout"
  fi
  have fzf   && ok "fzf $(fzf --version | awk '{print $1}') with built-in shell integration"
  have atuin && ok "atuin ready — run 'atuin register' or 'atuin login' to sync history"
}

# --- kitty ----------------------------------------------------------------
module_kitty() {
  header "Kitty"
  brew_install_cask kitty
  run mkdir -p "$HOME/.config/kitty"
  if run cp -r ./apps/kitty/. "$HOME/.config/kitty"/; then
    ok "kitty config copied"
  else
    err "could not copy the kitty config"
  fi
}

# --- default terminal -----------------------------------------------------
# macOS has no global "default terminal" setting the way GNOME does; what can
# be changed is which application opens shell scripts.
module_terminal() {
  header "Default terminal"
  if ! brew_cask_installed kitty && [[ ! -d /Applications/kitty.app ]]; then
    err "kitty is not installed; run ./install_mac.sh kitty first"
    return
  fi
  if have duti; then
    run duti -s net.kovidgoyal.kitty com.apple.terminal.shell-script all
    ok "kitty registered as the handler for shell scripts"
  else
    warn "duti not installed; cannot change the shell-script handler"
  fi
  info "macOS has no global default-terminal setting: pin kitty to the Dock manually"
}

# --- LLM CLIs -------------------------------------------------------------
module_llm() {
  header "LLM CLIs"
  have node || brew_install node

  if have claude; then
    ok "Claude Code $(claude --version 2>/dev/null | awk '{print $1}') already installed"
  else
    info "installing Claude Code"
    (( DRY_RUN )) || curl -fsSL https://claude.ai/install.sh | bash
  fi

  if have codex; then
    ok "Codex $(codex --version 2>/dev/null | awk '{print $NF}') already installed"
  elif have npm; then
    run npm install -g @openai/codex
  else
    warn "npm missing, skipping Codex"
  fi
}

# --- desktop applications -------------------------------------------------
# `docker` is the Docker Desktop cask; the CLI comes with it, so there is no
# separate docker formula here.
BREW_CASKS=(
  brave-browser bitwarden spotify telegram vlc slack thunderbird
  visual-studio-code sublime-text docker postman rectangle alt-tab
  powershell microsoft-teams
)

module_apps() {
  header "Desktop applications"
  brew_install_cask "${BREW_CASKS[@]}"
}

#------------
# Driver
#------------

MODULES=(system upgrade git fonts zsh shelltools kitty terminal llm apps)

usage() {
  cat <<EOF
Usage: ./install_mac.sh [--dry-run] [module ...]

Modules (all of them run when none is given):
  system      Homebrew formulae (shell, CLI tools, GNU coreutils)
  upgrade     brew update / upgrade / cleanup
  git         global git config (delta pager, sane defaults)
  fonts       Nerd Font casks and the fonts bundled here
  zsh         .zshrc, .p10k.zsh, tmux config, shell functions and plugins
  shelltools  fzf, zoxide and atuin
  kitty       kitty cask + config
  terminal    register kitty as the shell-script handler
  llm         Node.js and the AI CLIs
  apps        desktop application casks

Options:
  --dry-run   print the commands instead of running them
  --list      list module names
  -h, --help  this help

Powerlevel10k comes from its Homebrew formula; no Oh My Zsh is installed
because the .zshrc in this repository loads everything itself.
EOF
}

main() {
  local requested=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --list)    printf '%s\n' "${MODULES[@]}"; exit 0 ;;
      -h|--help) usage; exit 0 ;;
      -*)        err "Unknown option: $1"; usage; exit 1 ;;
      *)         requested+=("$1") ;;
    esac
    shift
  done

  require_macos
  require_not_root
  ensure_brew

  [[ ${#requested[@]} -eq 0 ]] && requested=("${MODULES[@]}")

  local m
  for m in "${requested[@]}"; do
    if [[ " ${MODULES[*]} " != *" $m "* ]]; then
      err "Unknown module: $m"
      continue
    fi
    "module_$m"
  done

  header "Summary"
  info "macOS        : $(sw_vers -productVersion 2>/dev/null)"
  info "Homebrew     : $BREW_PREFIX"
  info "Modules      : ${requested[*]}"
  [[ ${#SKIPPED[@]} -gt 0 ]] && warn "Not installed: ${SKIPPED[*]}"
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
