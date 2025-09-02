#!/usr/bin/env bash
set -euo pipefail

declare -A REPOS
REPOS["https://github.com/Tiramisu-Cake/myHyprland.git"]="$HOME/.config/hyprland"
REPOS["https://github.com/Tiramisu-Cake/myWaybar.git"]="$HOME/.config/waybar"
REPOS["https://github.com/Tiramisu-Cake/myAlacritty.git"]="$HOME/.config/alacritty"
REPOS["https://github.com/Tiramisu-Cake/wallpapers.git"]="$HOME/Pictures/wallpapers"
REPOS["https://github.com/Tiramisu-Cake/my_nvim_cfg.git"]="$HOME/.config/nvim"

need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  echo "Need command: $1"
  exit 1
}; }
is_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
SUDO=""
if ! is_root; then
  need_cmd sudo
  SUDO="sudo"
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/setup-repos"
mkdir -p "$cache_dir"

sync_repos() {
  for url in "${!REPOS[@]}"; do
    dir="${REPOS[$url]}"
    ssh_url=$(echo "$url" | sed -E 's#https://github.com/#git@github.com:#')

    if [ -d "$dir/.git" ]; then
      echo "=== We have this repo: $dir, let's update it... ==="
      git -C "$dir" pull --ff-only
    else
      echo "=== Cloning $url to $dir ==="
      git clone "$url" "$dir"
    fi

    echo "=== Setting $dir to ssh ==="
    git -C "$dir" remote set-url origin "$ssh_url"
  done
}

pac() { $SUDO pacman --noconfirm --needed -S "$@"; }
pac_sync() { $SUDO pacman --noconfirm -Syu; }

# Necessary packages
echo "==> System update and packages installation"
pac_sync

# Hyprland musthaves and others
pac hyprland hyprpolkitagent waybar hyprshot swappy hyprpicker \
  xdg-desktop-portal-hyprland hyprpaper hyprlock

pac alacritty git base-devel curl wget unzip zip rustup \
  networkmanager network-manager-applet bluez blueman \
  pipewire wireplumber pipewire-pulse pipewire-alsa \
  alsa-ucm-conf alsa-utils pavucontrol \
  polkit wl-clipboard cliphist \
  brightnessctl playerctl nwg-displays \
  xdg-desktop-portal \
  neovim nano ripgrep fd bat btop htop tree rsync jq tmux

# Fonts
pac inter-font ttf-noto-nerd noto-fonts noto-fonts-emoji ttf-dejavu ttf-firacode-nerd

#yazi
pac yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick ueberzugpp chafa

# Configure Rust
echo "==> Configuring Rust..."
rustup default stable

# yay - AUR helper
cd
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd
rm -rf yay-bin

# Docker
pac docker docker-compose docker-buildx
$SUDO systemctl disable --now docker.service
$SUDO systemctl enable --now docker.socket
yay -S lazydocker

# AUR packages
yay -S --needed tofi hyprland-per-window-layout
# AUR fonts
yay -S --needed otf-apple-fonts ttf-segoe-ui-variable

# Services
echo "==> Enabling services..."
$SUDO systemctl enable --now NetworkManager.service
$SUDO systemctl enable --now bluetooth.service || true

# tmux plugin manager
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## Starship (shell prompt)
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >>~/.bashrc

# Configs from repos
echo "==> pull configs"
mkdir -p "$HOME/.config"

sync_repos
ln -siv "$HOME/.config/alacritty/.tmux.conf" "$HOME/.tmux.conf"
