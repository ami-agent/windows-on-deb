#!/bin/bash
set -euo pipefail

echo "=== [01] Installing system dependencies ==="

if ! dpkg --print-foreign-architectures | grep -q i386; then
    echo "Enabling i386 architecture..."
    sudo dpkg --add-architecture i386
    sudo apt update
fi

sudo apt install -y \
    libvulkan1:i386 \
    mesa-vulkan-drivers:i386 \
    libgnutls30t64:i386 \
    libgl1-mesa-dri:i386 \
    libldap2:i386 \
    libgssapi-krb5-2:i386 \
    libgl1:i386 \
    mesa-vulkan-drivers \
    libvulkan1 \
    flatpak \
    winetricks \
    mangohud \
    vulkan-tools \
    acl \
    curl \
    wget

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Add user to render group (needed for Vulkan device access)
sudo usermod -aG render "$USER"

# Grant immediate render node access via ACL (no logout required)
RENDER_DEVS=$(ls /dev/dri/render* 2>/dev/null || true)
if [ -n "$RENDER_DEVS" ]; then
    sudo setfacl -m u:"$USER":rw $RENDER_DEVS
fi

echo ""
echo "=== [01] Complete ==="
echo "Next: run 02-install-steam.sh"
