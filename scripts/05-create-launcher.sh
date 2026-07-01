#!/bin/bash
set -euo pipefail

echo "=== [05] Creating D2R launch scripts ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

detect_ge_proton

# Launch script — uses Battle.net with --exec="launch OSI" to run D2R
LAUNCH_SCRIPT="$GAMES_DIR/launch-d2r.sh"
cat > "$LAUNCH_SCRIPT" << SCRIPTEOF
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"

# Try to load config from various relative locations
if [ -f "\$SCRIPT_DIR/config.env" ]; then
    source "\$SCRIPT_DIR/config.env"
elif [ -f "\$SCRIPT_DIR/scripts/config.env" ]; then
    source "\$SCRIPT_DIR/scripts/config.env"
else
    # Fallback defaults if config not found
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
        echo "ERROR: GE-Proton not found. Run 03-install-proton.sh first."
        exit 1
    fi
fi

: "\${BNET_PREFIX:=\$HOME/Games/battlenet-prefix}"
: "\${STEAM_ROOT:=\$HOME/.steam/root}"
: "\${COMPAT_TOOLS_DIR:=\$STEAM_ROOT/compatibilitytools.d}"
BNET_LAUNCHER="\$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"

if [ ! -f "\$BNET_LAUNCHER" ]; then
    echo "ERROR: Battle.net launcher not found at: \$BNET_LAUNCHER"
    echo "Run 04-install-battlenet.sh first."
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
export WINE_SIMULATE_WRITECOPY=1
export PROTON_USE_NTSYNC=1

exec "\$GE_PROTON_DIR/proton" run "\$BNET_LAUNCHER" --exec="launch OSI"
SCRIPTEOF
chmod +x "$LAUNCH_SCRIPT"

# Direct D2R launch script (bypasses Battle.net, requires D2R.exe path)
DIRECT_SCRIPT="$GAMES_DIR/launch-d2r-direct.sh"
cat > "$DIRECT_SCRIPT" << SCRIPTEOF
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

: "\${STEAM_ROOT:=\$HOME/.steam/root}"
: "\${BNET_PREFIX:=\$HOME/Games/battlenet-prefix}"

D2R_EXE_PATH="\${D2R_EXE_PATH:-\$HOME/Games/D2R/Diablo II Resurrected/D2R.exe}"

if [ ! -f "\$D2R_EXE_PATH" ]; then
    echo "ERROR: D2R.exe not found at: \$D2R_EXE_PATH"
    echo "Edit this script and set D2R_EXE_PATH to the correct path."
    echo "Search: find ~/Games -name 'D2R.exe' 2>/dev/null"
    exit 1
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH="\$STEAM_ROOT"
export STEAM_COMPAT_DATA_PATH="\$BNET_PREFIX"
export PROTON_USE_NTSYNC=1

exec "\$GE_PROTON_DIR/proton" run "\$D2R_EXE_PATH"
SCRIPTEOF
chmod +x "$DIRECT_SCRIPT"

# Extract icon from D2R.exe
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
ICON_PATH="$ICON_DIR/d2r.png"
mkdir -p "$ICON_DIR"

D2R_EXE="$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Diablo II Resurrected/D2R.exe"
if [ -f "$D2R_EXE" ] && command -v wrestool &>/dev/null && command -v icotool &>/dev/null; then
    echo "Extracting icon from D2R.exe..."
    wrestool -x -t 14 "$D2R_EXE" 2>/dev/null | icotool -x --width=256 --height=256 -o "$ICON_DIR" - 2>/dev/null || true
    # Rename extracted png if found
    EXTRACTED_PNG=$(ls "$ICON_DIR"/*.png 2>/dev/null | head -1)
    if [ -n "$EXTRACTED_PNG" ]; then
        mv "$EXTRACTED_PNG" "$ICON_PATH" 2>/dev/null || true
    fi
elif [ -f "$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe" ] && command -v wrestool &>/dev/null; then
    echo "Extracting icon from Battle.net.exe..."
    wrestool -x -t 14 "$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Battle.net/Battle.net.exe" 2>/dev/null | icotool -x --width=256 --height=256 -o "$ICON_DIR" - 2>/dev/null || true
    EXTRACTED_PNG=$(ls "$ICON_DIR"/*.png 2>/dev/null | head -1)
    if [ -n "$EXTRACTED_PNG" ]; then
        mv "$EXTRACTED_PNG" "$ICON_PATH" 2>/dev/null || true
    fi
fi
# Fallback: use Steam icon if nothing extracted
if [ ! -f "$ICON_PATH" ]; then
    if [ -f "$HOME/.steam/steam/steam.png" ]; then
        cp "$HOME/.steam/steam/steam.png" "$ICON_PATH"
    fi
fi

# Use the Arc workaround launcher if it exists (it includes GPU fixes + render ACL)
FINAL_LAUNCHER="$LAUNCH_SCRIPT"
if [ -f "$GAMES_DIR/launch-d2r-arc.sh" ]; then
    FINAL_LAUNCHER="$GAMES_DIR/launch-d2r-arc.sh"
fi

# Desktop entry
DESKTOP_FILE="$HOME/.local/share/applications/d2r.desktop"
mkdir -p "$HOME/.local/share/applications"
cat > "$DESKTOP_FILE" << DESKTOPDF
[Desktop Entry]
Name=Diablo II: Resurrected
Comment=Launch D2R via Battle.net (GE-Proton)
Exec=$FINAL_LAUNCHER
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Game;ActionGame;
StartupNotify=true
StartupWMClass=D2R.exe
Actions=launch-bnet;

[Desktop Action launch-bnet]
Name=Launch Battle.net Launcher
Exec=$GAMES_DIR/launch-d2r.sh
DESKTOPDF

# Copy to ~/Desktop for desktop icon (GNOME)
if [ -d "$HOME/Desktop" ]; then
    cp "$DESKTOP_FILE" "$HOME/Desktop/d2r.desktop"
    chmod +x "$HOME/Desktop/d2r.desktop"
    echo "  ~/Desktop/d2r.desktop"
fi

# Register with desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo "=== [05] Created ==="
echo "  $LAUNCH_SCRIPT        — Launch D2R via Battle.net"
echo "  $DIRECT_SCRIPT        — Launch D2R.exe directly (edit D2R_EXE_PATH)"
echo "  $DESKTOP_FILE"
echo "  Icon: $ICON_PATH"
echo ""
echo "If D2R fails on Intel Arc (black screen/crash), run:"
echo "  06-apply-arc-workarounds.sh"
