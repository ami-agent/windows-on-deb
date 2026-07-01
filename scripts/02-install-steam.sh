#!/bin/bash
set -euo pipefail

echo "=== [02] Installing Steam ==="

if dpkg -s steam-installer &>/dev/null; then
    echo "Steam already installed."
else
    sudo apt install -y steam-installer
fi

mkdir -p "$HOME/.steam/root/compatibilitytools.d"

echo "=== [02] Complete ==="
echo ""
echo "Launch Steam at least once to complete setup:"
echo "  steam &"
echo "Let it update and log in, then quit."
echo ""
echo "After that, run: 03-install-proton.sh"
