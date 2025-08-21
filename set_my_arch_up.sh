#!/usr/bin/env bash
set -euo pipefail

HYPR_REPO="${HYPR_REPO:-https://github.com/Tiramisu-Cake/myHyprland}"
WAYBAR_REPO="${WAYBAR_REPO:-https://github.com/Tiramisu-Cake/myWaybar.git}"
ALACRITTY_REPO="${ALACRITTY_REPO:-https://github.com/Tiramisu-Cake/myAlacritty.git}"
WALLPAPERS_REPO="${WALLPAPERS_REPO:-https://github.com/Tiramisu-Cake/wallpapers.git}"
NEOVIM_REPO="${NEOVIM_REPO:-https://github.com/Tiramisu-Cake/my_nvim_cfg.git}"


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

# Hyprland musthaves and others
pac hyprland hyprpolkitagent waybar hyprshot swappy hyprpicker \
    xdg-desktop-portal-hyprland hyprpaper hyprlock

pac git base-devel curl wget unzip zip rustup \
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

# AUR packages
yay -S --needed tofi hyprland-per-window-layout

# AUR fonts
yay  -S --needed otf-apple-fonts ttf-segoe-ui-variable

# Services
echo "==> Enabling services..."
$SUDO systemctl enable --now NetworkManager.service
$SUDO systemctl enable --now bluetooth.service || true

# Alacritty terminal
echo "==> Installing Alacritty..."
cd
git clone https://github.com/alacritty/alacritty.git
cd alacritty
pac cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python
cargo build --release
sudo cp target/release/alacritty /usr/bin
mkdir -p ~/.bash_completion
cp extra/completions/alacritty.bash ~/.bash_completion/alacritty
echo "source ~/.bash_completion/alacritty" >> ~/.bashrc
cd
rm -rf alacritty

# tmux plugin manager
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## Starship (shell prompt)
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Configs from repos
echo "==> pull configs"
mkdir -p "$HOME/.config"

sync_repo "$HYPR_REPO"      "" "$HOME/.config/hypr"
sync_repo "$WAYBAR_REPO"    "" "$HOME/.config/waybar"
sync_repo "$ALACRITTY_REPO" "" "$HOME/.config/alacritty"
sync_repo "$WALLPAPERS_REPO" "" "$HOME/Pictures/wallpapers"
sync_repo "$NEOVIM_REPO" "" "$HOME/.config/nvim"

ln -siv "$HOME/.config/alacritty/.tmux.conf" "$HOME/.tmux.conf"

cd $HOME/.config/hypr
git remote set-url origin git@github.com:Tiramisu-Cake/myHyprland.git

cd $HOME/.config/waybar
git remote set-url origin git@github.com:Tiramisu-Cake/myWaybar.git

cd $HOME/.config/alacritty
git remote set-url origin git@github.com:Tiramisu-Cake/myAlacritty.git

cd $HOME/Pictures/wallpapers
git remote set-url origin git@github.com:Tiramisu-Cake/wallpapers.git

cd $HOME/.config/nvim
git remote set-url origin git@github.com:Tiramisu-Cake/my_nvim_cfg.git

cd $HOME/myArch
git remote set-url origin git@github.com:Tiramisu-Cake/myArch.git
