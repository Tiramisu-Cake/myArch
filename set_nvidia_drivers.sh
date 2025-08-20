#!/usr/bin/env bash
set -euo pipefail

sudo pacman -Syu
sudo pacman -S nvidia-dkms nvidia-utils nvidia-settings linux-headers

echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
sudo mkinitcpio -P

echo "You have to write the following options to the \'options' line of your /boot/loader/entries/*.conf:"
echo "nvidia_drm.modeset=1 modprobe.blacklist=nouveau"
