# Installation script for Linux systems

This script automates the installation and configuration process of various tools and applications on a Linux system.

## Requirements
- A Linux system with apt package manager installed
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
3. Make the script executable:
chmod +x install
4. Run the script as an administrator:
sudo ./install

## Features
- Updates and upgrades the system
- Installs required packages and tools (e.g. zsh, git, vim, tmux)
- Installs local applications in the ~/Linux/apps directory
- Installs fonts in the ~/.fonts directory
- Configures zsh and sets it as the default shell for the current user and root
- Installs the powerlevel10k theme for zsh
- Installs SNAP applications (e.g. searchsploit, mysql-shell)
- Installs the fzf fuzzy finder tool
- Displays a fortune message after the script finishes executing

## Note
- The script assumes that the required files (e.g. local applications, fonts, zsh configuration files) are in the same directory as the script.
- The script has been tested on a Ubuntu 22.02 and Parrot OS and may need modifications to work on other systems.
- Use the script at your own risk, as it modifies the system configuration.