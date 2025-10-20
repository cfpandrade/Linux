# Installation script for Linux systems

This repository contains a single installation script that prepares a Linux system with common tools, fonts and shell configuration.  The script automatically detects the package manager available on the host (apt, dnf or yum) so it can be used on a variety of distributions.

## Requirements
- A Linux system with either apt, dnf or yum package manager installed
- Administrative privileges to run the script (e.g. sudo)
- The following tools and packages need to be pre-installed:
  - bash
  - git

## Usage
To use the script, follow these steps:
1. Clone the repository containing the script and required files:
git clone https://github.com/cfpandrade/Linux
2. Navigate to the repository directory:
cd Linux
3. Run the script as an administrator:
sudo ./install.sh

## Features
- Updates and upgrades the system
- Installs required packages and tools (e.g. zsh, git, vim, tmux)
- Installs local applications in the ~/Linux/apps directory
- Installs fonts in the ~/.fonts directory
- Configures zsh and sets it as the default shell for the current user and root
- Installs the powerlevel10k theme for zsh
- Installs SNAP applications listed in `snap_packages.txt`
- Installs the fzf fuzzy finder tool
- Displays a fortune message after the script finishes executing

### New Improvements (v2.0)
- **Comprehensive logging**: All actions are logged to `~/linux-install.log` with timestamps
- **Error handling**: Robust error checking and graceful degradation when components fail
- **Idempotent operations**: Safe to run multiple times - skips already installed components
- **Smart updates**: Updates existing installations (e.g., PowerLevel10k, FZF) instead of failing
- **Backup protection**: Automatically backs up existing configuration files (e.g., .zshrc)
- **Configurable installation**: Use `install.conf` to selectively enable/disable components
- **Better validation**: Checks for required files and directories before proceeding
- **Detailed progress**: Color-coded output showing what's being installed and any issues

### Customization

#### Snap Packages
The list of snap packages installed by the script is stored in `snap_packages.txt`. Edit this file to add or remove applications without modifying the script itself. Lines starting with `#` are treated as comments.

#### Installation Components
To customize which components are installed:
1. Copy the example configuration:
   ```bash
   cp install.conf.example install.conf
   ```
2. Edit `install.conf` and set any component to `false` to skip it:
   ```bash
   INSTALL_KITTY=false        # Skip Kitty terminal installation
   INSTALL_SNAP_APPS=false    # Skip all snap apps
   ```
3. Run the script normally - it will respect your configuration

#### Custom Log Location
Set a custom log file location by editing `install.conf`:
```bash
LOGFILE="/path/to/custom/install.log"
```

## Note
- The script assumes that the required files (e.g. local applications, fonts, zsh configuration files) are in the same directory as the script. You can replace the fonts under `fonts/` with your favourites before running it.
- The script has been tested on Ubuntu 22.02 and Parrot OS and may need modifications to work on other systems.
- Use the script at your own risk, as it modifies the system configuration.
