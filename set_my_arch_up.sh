#!/usr/bin/env bash
set -euo pipefail

HYPR_REPO="${HYPR_REPO:-https://github.com/Tiramisu-Cake/myHyprland}"
WAYBAR_REPO="${WAYBAR_REPO:-}"
ALACRITTY_REPO="${ALACRITTY_REPO:-}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Need command: $1"; exit 1; }; }
is_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
SUDO=""
if ! is_root; then
  need_cmd sudo
  SUDO="sudo"
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/setup-repos"
mkdir -p "$cache_dir"

sync_repo() { # repo_url subpath target_dir
  local url="$1" sub="$2" target="$3"
  [ -z "$url" ] && return 0
  local name="$(basename "${url%.git}")"
  local work="$cache_dir/$name"
  if [ -d "$work/.git" ]; then
    git -C "$work" pull --ff-only
  else
    git clone --depth=1 "$url" "$work"
  fi
  mkdir -p "$target"
  if [ -n "$sub" ]; then
    rsync -a --delete "$work/$sub/" "$target/"
  else
    rsync -a --delete "$work/" "$target/"
  fi
}

pac() { $SUDO pacman --noconfirm --needed -S "$@"; }
pac_sync() { $SUDO pacman --noconfirm -Syu; }

# Necessary packages
echo "==> System update and packages installation" 
pac_sync
pac git base-devel curl wget unzip zip rustup \
    networkmanager network-manager-applet bluez blueman \
    pipewire wireplumber pipewire-pulse pipewire-alsa \
    alsa-ucm-conf alsa-utils pavucontrol \
    polkit hyprpolkitagent hyprland waybar \
    wl-clipboard cliphist hyprshot swappy \
    brightnessctl playerctl \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    noto-fonts noto-fonts-emoji ttf-dejavu \
    neovim nano ripgrep fd bat btop htop tree rsync jq tmux

# yay - AUR helper
cd
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd
rm -rf yay-bin

# AUR packages
yay -S tofi

# Alacritty terminal
cd
git clone https://github.com/alacritty/alacritty.git
cd alacritty
pac cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python
cargo build --release
mkdir -p ~/.bash_completion
cp extra/completions/alacritty.bash ~/.bash_completion/alacritty
echo "source ~/.bash_completion/alacritty" >> ~/.bashrc
cd
rm -rf alacritty

## Starship (shell prompt)
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Configs from repos
echo "==> pull configs"
mkdir -p "$HOME/.config"

sync_repo "$HYPR_REPO"      "" "$HOME/.config/hypr"
sync_repo "$WAYBAR_REPO"    "" "$HOME/.config/waybar"
sync_repo "$ALACRITTY_REPO" "" "$HOME/.config/alacritty"
