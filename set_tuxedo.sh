#!/usr/bin/env bash
set -euo pipefail

yay -Syu
yay -S tuxedo-drivers-dkms tuxedo-control-center-bin linux-headers

sudo systemctl enable --now tccd.service

echo 'options tuxedo-keyboard kbd_backlight_mode=2' | sudo tee /etc/modprobe.d/99-tuxedo-keyboard-override.conf
