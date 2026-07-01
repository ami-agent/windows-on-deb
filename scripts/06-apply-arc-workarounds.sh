#!/bin/bash
set -euo pipefail

echo "=== [06] Intel Arc A770 Workarounds ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

detect_ge_proton

# Fix Vulkan render node access
RENDER_DEVS=$(ls /dev/dri/render* 2>/dev/null || true)
if [ -n "$RENDER_DEVS" ]; then
    if ! groups | grep -q render; then
        echo "Adding user to 'render' group (sudo required)..."
        sudo usermod -aG render "$USER"
    fi
    sudo setfacl -m u:"$USER":rw $RENDER_DEVS
fi

# Set Windows version to 10 in the Proton prefix
echo "Setting Windows version to 10..."
WINEPREFIX="$BNET_PREFIX/pfx" \
WINE="$GE_PROTON_DIR/files/bin/wine" \
WINESERVER="$GE_PROTON_DIR/files/bin/wineserver" \
"$GE_PROTON_DIR/files/bin/wine" reg add "HKEY_CURRENT_USER\Software\Wine" /v Version /d win10 /f 2>/dev/null || true

if [ ! -d "$BNET_INSTALL_DIR" ]; then
    echo "ERROR: Battle.net not found at: $BNET_INSTALL_DIR"
    echo "Run 04-install-battlenet.sh and install D2R through Battle.net first."
    exit 1
fi

# dxvk.conf — spoofs GPU as NVIDIA GTX 1080 to pass D2R's GPU capability check
echo "Creating dxvk.conf in Battle.net directory..."
cat > "$BNET_INSTALL_DIR/dxvk.conf" << 'EOF'
dxgi.customDeviceId = 10de
dxgi.customVendorId = 1b80
d3d12.maxResourceHeapSize = 2147483648
EOF

if [ -d "$D2R_DATA_DIR" ]; then
    echo "Creating dxvk.conf in D2R data directory..."
    cat > "$D2R_DATA_DIR/dxvk.conf" << 'EOF'
dxgi.customDeviceId = 10de
dxgi.customVendorId = 1b80
d3d12.maxResourceHeapSize = 2147483648
EOF
fi

# Arc-specific launch script with workaround env vars
LAUNCH_ARC="$GAMES_DIR/launch-d2r-arc.sh"
cat > "$LAUNCH_ARC" << SCRIPTEOF
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"

if [ -f "\$SCRIPT_DIR/config.env" ]; then
    source "\$SCRIPT_DIR/config.env"
elif [ -f "\$SCRIPT_DIR/scripts/config.env" ]; then
    source "\$SCRIPT_DIR/scripts/config.env"
else
    BNET_PREFIX="\$HOME/Games/battlenet-prefix"
    STEAM_ROOT="\$HOME/.steam/root"
    COMPAT_TOOLS_DIR="\$STEAM_ROOT/compatibilitytools.d"
    find_ge_proton() {
        local dir
        for dir in "\$COMPAT_TOOLS_DIR"/GE-Proton*/; do
            if [ -f "\$dir/proton" ] && [ -f "\$dir/files/bin/wine" ] && file "\$dir/files/bin/wine" 2>/dev/null | grep -q "x86-64"; then
                GE_PROTON_DIR="\$dir"
                return 0
            fi
        done
        return 1
    }
    if ! find_ge_proton; then
        echo "ERROR: GE-Proton not found."
        exit 1
    fi
fi

: "\${BNET_PREFIX:=\$HOME/Games/battlenet-prefix}"
: "\${STEAM_ROOT:=\$HOME/.steam/root}"

BNET_LAUNCHER="\$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"

if [ ! -f "\$BNET_LAUNCHER" ]; then
    echo "ERROR: Battle.net not found at: \$BNET_LAUNCHER"
    exit 1
fi

# Kill leftover processes from previous runs
killall -9 D2R.exe Battle.net.exe Agent.exe wineserver 2>/dev/null || true

# Ensure Vulkan render node access
for dev in /dev/dri/render*; do
    if [ -e "\$dev" ] && [ ! -r "\$dev" ]; then
        sudo setfacl -m u:"\$USER":rw "\$dev" 2>/dev/null || true
    fi
done

export STEAM_COMPAT_CLIENT_INSTALL_PATH="\$STEAM_ROOT"
export STEAM_COMPAT_DATA_PATH="\$BNET_PREFIX"

# Intel Arc A770 workarounds
export WINE_SIMULATE_WRITECOPY=1
export PROTON_USE_NTSYNC=1
export DXVK_NVAPI_DRIVER_VERSION=46091
export VKD3D_FEATURE_LEVEL=12_0
export VKD3D_CONFIG=no_upload_hvv

exec "\$GE_PROTON_DIR/proton" run "\$BNET_LAUNCHER" --exec="launch OSI"
SCRIPTEOF
chmod +x "$LAUNCH_ARC"

echo "=== [06] Complete ==="
echo ""
echo "Created: $LAUNCH_ARC"
echo ""
echo "Try launchers in order:"
echo "  1. $GAMES_DIR/launch-d2r.sh"
echo "  2. $LAUNCH_ARC"
echo ""
echo "Debug with:"
echo "  export WINEDEBUG=+vulkan,+d3d12"
echo "  $LAUNCH_ARC 2>&1 | tee /tmp/d2r-debug.log"
