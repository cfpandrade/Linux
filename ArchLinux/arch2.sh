!#/bin/bash

echo "UserName:"
read user

# Git checking
pacman -S git awesome-git --noconfirm

# WPA_supplicant
systemctl start wpa_supplicant.service
systemctl enable wpa_supplicant.service

# AUR
mkdir -p /home/$user/Desktop/$user/repos
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd ..

#Black Arch
mkdir blackarch
cd blackarch
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
sudo ./strap.sh

# Neofetch
pacman -S neofetch --noconfirm

# Xorg
pacman -S xorg xorg-server --noconfirm

#Gnome
pacman -S gnome gnome-extra --noconfirm

# Graphical interface
systemctl enable gdm.service

# Kitty
pacman -S kitty --noconfirm

#Gtkmm
pacman -S gtkmm --noconfirm

# Open VmTools
pacman -S open-vm-tools --noconfirm

# xf86-video-vmware
pacman -S xf86-video-vmware xf86-input-vmmouse --noconfirm

#Daemon VMtools
systemctl enable vmtoolsd.service

# Applications
pacman -S firefox wget p7zip --noconfirm

# Install awesome
paru -Sy picom-git wezterm rofi acpi acpid acpi_call upower lxappearance-gtk3 \
jq inotify-tools polkit-gnome xdotool xclip gpick ffmpeg blueman redshift \
pipewire pipewire-alsa pipewire-pulse pamixer brightnessctl feh scrot \
mpv mpd mpc mpdris2 python-mutagen ncmpcpp playerctl --needed

systemctl --user enable mpd.service
systemctl --user start mpd.service

############ FONTS ##############
# Install fonts
cd /usr/share/fonts
wget https://fontlot.com/downfile/5baeb08d06494fc84dbe36210f6f0ad5.105610
mv 5baeb08d06494fc84dbe36210f6f0ad5.105610 complete.zip
unzip complete.zip
rm complete.zip

# move ttf files
find . | grep "\.ttf$" | while read line; do cp $line .; do
rm -r iosevka-2.2.1/
rm -r iosevka-slab-2.2.1/

# wget icomoon

# paru fonts
paru -Sy nerd-fonts-jetbrains-mono ttf-font-awesome ttf-font-awesome-4 ttf-material-design-icons


#################################

# Install awesome dotfiles

cd ~/Desktop/$user/repos
git clone --recurse-submodules https://github.com/rxyhn/dotfiles.git
cd dotfiles && git submodule update --remote --merge
# Copy files
cp -r config/* ~/.config/cp -r misc/fonts/* ~/.fonts/
# or to ~/.local/share/fonts
cp -r misc/fonts/* ~/.local/share/fonts/
fc-cache -v




