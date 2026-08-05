# actualizar - one command to update the whole workstation.
# Depends on the helpers in ui.zsh (imprimir_linea / centrar_texto / seccion).

_trezor_suite_upgrade() {
  local latest_yml_url="https://data.trezor.io/suite/releases/desktop/latest/latest-linux.yml"
  local latest_base_url="https://data.trezor.io/suite/releases/desktop/latest"
  local signing_key_url="https://trezor.io/security/satoshilabs-2021-signing-key.asc"
  local target="/opt/trezor-suite/Trezor-Suite.AppImage"
  local key_fpr="EB483B26B078A4AA1B6F425EE21B6950A2ECB65C"
  local temp_dir gpg_home latest_yml app_name app_url sig_url app_path sig_path key_path
  local expected_sha512 actual_sha512 installed_sha512 imported_fpr backup_path

  if ! command -v curl &> /dev/null || ! command -v gpg &> /dev/null ||
     ! command -v sha512sum &> /dev/null || ! command -v base64 &> /dev/null ||
     ! command -v xxd &> /dev/null || ! command -v timeout &> /dev/null; then
    echo "  Missing required tools for Trezor Suite update."
    return
  fi

  if [[ ! -f "$target" ]]; then
    echo "  Trezor Suite AppImage install not found at $target"
    return
  fi

  if lsof "$target" >/dev/null 2>&1; then
    echo "  Trezor Suite is currently running. Close it and run actualizar again."
    return
  fi

  latest_yml=$(curl -fsSL "$latest_yml_url") || {
    echo "  Could not fetch Trezor Suite release metadata"
    return
  }

  app_name=$(printf '%s\n' "$latest_yml" | sed -n 's/^path: //p' | head -n1)
  expected_sha512=$(printf '%s\n' "$latest_yml" | sed -n 's/^sha512: //p' | head -n1)

  if [[ -z "$app_name" || -z "$expected_sha512" ]]; then
    echo "  Release metadata is incomplete"
    return
  fi

  expected_sha512=$(printf '%s' "$expected_sha512" | base64 -d | xxd -p -c 999)
  installed_sha512=$(sha512sum "$target" 2>/dev/null | awk '{print $1}')
  if [[ "$installed_sha512" == "$expected_sha512" ]]; then
    echo "  Trezor Suite is already up to date ($app_name)"
    return
  fi

  temp_dir=$(mktemp -d)
  gpg_home="$temp_dir/gnupg"
  mkdir -p "$gpg_home"
  chmod 700 "$gpg_home"

  app_url="$latest_base_url/$app_name"
  sig_url="$app_url.asc"
  app_path="$temp_dir/$app_name"
  sig_path="$app_path.asc"
  key_path="$temp_dir/satoshilabs-2021-signing-key.asc"

  echo "  Downloading $app_name"
  curl -fL --progress-bar "$app_url" -o "$app_path" || {
    echo "  Failed to download $app_name"
    /bin/rm -rf "$temp_dir"
    return
  }

  curl -fsSL "$sig_url" -o "$sig_path" || {
    echo "  Failed to download signature file"
    /bin/rm -rf "$temp_dir"
    return
  }

  curl -fsSL "$signing_key_url" -o "$key_path" || {
    echo "  Failed to download SatoshiLabs signing key"
    /bin/rm -rf "$temp_dir"
    return
  }

  imported_fpr=$(gpg --homedir "$gpg_home" --batch --show-keys --with-colons --fingerprint "$key_path" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
  if [[ "$imported_fpr" != "$key_fpr" ]]; then
    echo "  Signing key fingerprint mismatch: $imported_fpr"
    /bin/rm -rf "$temp_dir"
    return
  fi

  echo "  Importing SatoshiLabs signing key"
  gpg --homedir "$gpg_home" --batch --import "$key_path" >/dev/null 2>&1 || {
    echo "  Failed to import SatoshiLabs signing key"
    /bin/rm -rf "$temp_dir"
    return
  }

  echo "  Verifying release signature"
  gpg --homedir "$gpg_home" --batch --verify "$sig_path" "$app_path" >/dev/null 2>&1 || {
    echo "  GPG signature verification failed"
    /bin/rm -rf "$temp_dir"
    return
  }

  actual_sha512=$(sha512sum "$app_path" | awk '{print $1}')
  if [[ "$actual_sha512" != "$expected_sha512" ]]; then
    echo "  SHA-512 mismatch after download"
    /bin/rm -rf "$temp_dir"
    return
  fi

  backup_path="$HOME/.cache/trezor-suite-backups/Trezor-Suite.AppImage.$(date +%F-%H%M%S).bak"
  mkdir -p "$HOME/.cache/trezor-suite-backups"

  echo "  Installing verified release into $target"
  /bin/cat "$target" > "$backup_path" &&
    /bin/cat "$app_path" > "$target" &&
    chmod 755 "$target" &&
    echo "  Trezor Suite updated successfully"

  /bin/rm -rf "$temp_dir"
}

_kitty_upgrade() {
  local installed latest newest
  if command -v kitty &> /dev/null; then
    installed=$(kitty --version | awk '{print $2}')
  fi

  latest=$(curl -fsSL https://api.github.com/repos/kovidgoyal/kitty/releases/latest | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -n 1)
  if [[ -z "$latest" ]]; then
    echo "  Could not check latest Kitty version. Skipping."
    return
  fi

  if [[ -z "$installed" ]]; then
    echo "  Kitty not installed - installing v$latest..."
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    echo "  Kitty installed at v$latest"
    return
  fi

  newest=$(printf "%s\n%s\n" "$installed" "$latest" | sort -V | tail -n 1)
  if [[ "$newest" == "$latest" && "$installed" != "$latest" ]]; then
    echo "  Kitty v$installed, upgrading to v$latest..."
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    echo "  Kitty upgraded to v$latest"
  else
    echo "  Kitty v$installed, no upgrade needed"
  fi
}

_git_repo_upgrade() {
  local dir=$1 label=$2
  [[ -d "$dir/.git" ]] || { echo "  $label not installed at $dir"; return }
  if [[ -w "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only --quiet 2>/dev/null
  else
    sudo git -C "$dir" pull --ff-only --quiet 2>/dev/null
  fi
  if [[ $? -eq 0 ]]; then
    echo "  $label up to date ($(git -C "$dir" rev-parse --short HEAD 2>/dev/null))"
  else
    echo "  Could not update $label"
  fi
}

_npm_upgrade() {
  local pkg=$1 label=$2
  local installed latest
  installed=$(npm list -g --depth=0 "$pkg" 2>/dev/null | awk -F@ "/${pkg//\//\\/}@/ {print \$NF; exit}")
  latest=$(timeout 20s npm view "$pkg" version 2>/dev/null)
  if [[ -z "$latest" ]]; then
    echo "  Could not check latest $label version. Skipping."
    return
  fi
  if [[ -z "$installed" ]]; then
    echo "  $label not installed — installing v$latest..."
    sudo npm install -g "$pkg"
    echo "  $label installed at v$latest"
  elif [[ "$installed" == "$latest" ]]; then
    echo "  $label v$installed, no upgrade needed"
  else
    echo "  $label v$installed, upgrading to v$latest..."
    sudo npm install -g "$pkg"
    echo "  $label upgraded to v$latest"
  fi
}

# CLI that ships its own installer script and is versioned on the npm registry.
_script_cli_upgrade() {
  local bin=$1 label=$2 registry_pkg=$3 installer=$4
  local installed latest newest
  if command -v "$bin" &> /dev/null; then
    installed=$("$bin" --version 2>/dev/null | awk '{print $1}')
  fi

  latest=$(timeout 20s npm view "$registry_pkg" version 2>/dev/null)
  if [[ -z "$latest" ]]; then
    echo "  Could not check latest $label version. Skipping."
    return
  fi

  if [[ -z "$installed" ]]; then
    echo "  $label not installed - installing v$latest..."
    curl -fsSL "$installer" | bash
    return
  fi

  newest=$(printf "%s\n%s\n" "$installed" "$latest" | sort -V | tail -n 1)
  if [[ "$newest" == "$latest" && "$installed" != "$latest" ]]; then
    echo "  $label v$installed, upgrading to v$latest..."
    curl -fsSL "$installer" | bash
    echo "  $label upgraded to v$latest"
  else
    echo "  $label v$installed, no upgrade needed"
  fi
}

function actualizar() {
  clear

  seccion "Updating the repositories"
  sudo apt update

  seccion "Doing a full upgrade"
  sudo apt -y full-upgrade
  sudo apt list --upgradable 2>/dev/null | awk -F/ '/upgradable/ {print $1}' | xargs -r sudo apt -y --allow-change-held-packages install

  if command -v snap &> /dev/null; then
    seccion "Updating SNAP Installs"
    sudo snap refresh
  else
    seccion "Snap is not installed"
  fi

  if command -v flatpak &> /dev/null; then
    seccion "Updating Flatpak Apps"
    flatpak update -y
    flatpak uninstall --unused -y
  else
    seccion "Flatpak is not installed"
  fi

  seccion "Updating Kitty Terminal"
  _kitty_upgrade

  seccion "Updating git-based tools"
  _git_repo_upgrade /usr/share/powerlevel10k "Powerlevel10k"

  if command -v gh &> /dev/null; then
    seccion "Updating gh extensions"
    gh extension upgrade --all 2>/dev/null || echo "  No gh extensions installed"
  fi

  if command -v cargo &> /dev/null && cargo install --list 2>/dev/null | grep -q .; then
    seccion "Updating cargo binaries"
    if command -v cargo-install-update &> /dev/null; then
      cargo install-update -a
    else
      echo "  Install cargo-update (cargo install cargo-update) to refresh these automatically"
      cargo install --list | grep -E '^\S+ v' | sed 's/^/  /'
    fi
  fi

  if command -v fwupdmgr &> /dev/null; then
    seccion "Updating firmware"
    sudo fwupdmgr refresh --force >/dev/null 2>&1
    sudo fwupdmgr get-updates 2>/dev/null && sudo fwupdmgr update -y 2>/dev/null
  fi

  if command -v pipx &> /dev/null; then
    seccion "Updating pipx packages"
    pipx upgrade-all
  fi

  seccion "Updating LLM Tools"
  _script_cli_upgrade claude "Claude Code" "@anthropic-ai/claude-code" "https://claude.ai/install.sh"
  _npm_upgrade @openai/codex "Codex"

  seccion "Updating Trezor Suite AppImage"
  _trezor_suite_upgrade

  seccion "Removing old packages and/or fixing broken packages"
  sudo apt -y autoremove || sudo apt --fix-broken install && sudo apt -y autoremove

  imprimir_linea
  imprimir_linea

  if [ -f /var/run/reboot-required ]; then
      echo
      centrar_texto "*******************"
      centrar_texto "* Reboot Required *"
      centrar_texto "*******************"
      echo
      echo -n "Do you want to reboot now? (y/n): "
      read -r -k 1 -s -t 60 choice
      echo  # Ensure a new line after input
      if [[ $choice =~ ^[Yy]$ ]]; then
        sudo reboot now
      elif [[ $choice =~ ^[Nn]$ || -z $choice ]]; then
        echo "Reboot skipped. You can reboot later."
      else
        echo "Invalid choice. Skipping reboot."
      fi
  else
      echo
      centrar_texto "***********************"
      centrar_texto "* Reboot NOT Required *"
      centrar_texto "***********************"
      echo
  fi
}
