#!/usr/bin/env bash
set -euo pipefail

declare -A REPOS
REPOS["https://github.com/Tiramisu-Cake/myHyprland.git"]="$HOME/.config/hypr"
REPOS["https://github.com/Tiramisu-Cake/myWaybar.git"]="$HOME/.config/waybar"
REPOS["https://github.com/Tiramisu-Cake/myAlacritty.git"]="$HOME/.config/alacritty"
REPOS["https://github.com/Tiramisu-Cake/wallpapers.git"]="$HOME/Pictures/wallpapers"
REPOS["https://github.com/Tiramisu-Cake/my_nvim_cfg.git"]="$HOME/.config/nvim"

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

sync_repos
