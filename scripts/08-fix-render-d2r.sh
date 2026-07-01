#!/bin/bash
set -euo pipefail

echo "=== [08] Fix Vulkan render access + D2R launch ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

detect_ge_proton

# Fix 1: Add user to render group (persistent, needs re-login for effect)
if ! groups | grep -q render; then
    echo "Adding user to 'render' group..."
    sudo usermod -aG render "$USER"
fi

# Fix 2: Grant immediate render node access via ACL
echo "Granting immediate Vulkan device access..."
RENDER_DEVS=$(ls /dev/dri/render* 2>/dev/null || true)
if [ -n "$RENDER_DEVS" ]; then
    sudo setfacl -m u:"$USER":rw $RENDER_DEVS
fi

# Fix 3: Verify Vulkan works
echo "Verifying Vulkan..."
vulkaninfo --summary 2>&1 | grep -E "deviceName|GPU id" | head -5 || echo "WARNING: Vulkan check failed - driver may not be loaded"

# Fix 4: Set Windows 10 mode using GE-Proton's wine
echo "Setting Windows 10 mode in prefix..."
WINEPREFIX="$BNET_PREFIX/pfx" \
WINE="$GE_PROTON_DIR/files/bin/wine" \
WINESERVER="$GE_PROTON_DIR/files/bin/wineserver" \
"$GE_PROTON_DIR/files/bin/wine" reg add "HKEY_CURRENT_USER\Software\Wine" /v Version /d win10 /f

# Verify Windows version
echo "Windows version in prefix:"
WINEPREFIX="$BNET_PREFIX/pfx" "$GE_PROTON_DIR/files/bin/wine" --version
grep "HKEY_CURRENT_USER.*Wine" "$BNET_PREFIX/pfx/user.reg" -A1 2>/dev/null | head -3 || true

# Fix 5: Kill leftover processes
echo "Cleaning up leftover processes..."
killall -9 D2R.exe Battle.net.exe Agent.exe wineserver 2>/dev/null || true
sleep 1

echo ""
echo "=== [08] Complete ==="
echo ""
echo "Now launch D2R with:"
echo "  ~/Games/launch-d2r.sh"
echo "  (or ~/Games/launch-d2r-arc.sh if the standard one fails)"
