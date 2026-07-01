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
ICON_BASE="$HOME/.local/share/icons/hicolor"
mkdir -p "$ICON_BASE/256x256/apps" "$ICON_BASE/48x48/apps"
TMP_ICO="/tmp/d2r-icon.ico"
rm -f "$TMP_ICO"

D2R_EXE="$BNET_PREFIX/pfx/drive_c/Program Files (x86)/Diablo II Resurrected/D2R.exe"
if [ -f "$D2R_EXE" ] && command -v wrestool &>/dev/null && command -v icotool &>/dev/null; then
    echo "Extracting icon from D2R.exe..."
    wrestool -x -t 14 "$D2R_EXE" 2>/dev/null > "$TMP_ICO"
    if [ -s "$TMP_ICO" ]; then
        icotool -x --width=256 --height=256 -o "$ICON_BASE/256x256/apps" "$TMP_ICO" 2>/dev/null || true
        icotool -x --width=48 --height=48 -o "$ICON_BASE/48x48/apps" "$TMP_ICO" 2>/dev/null || true
        # Rename extracted pngs
        for sz in 256 48; do
            found=$(ls "$ICON_BASE/${sz}x${sz}/apps"/*.png 2>/dev/null | head -1)
            if [ -n "$found" ]; then
                mv "$found" "$ICON_BASE/${sz}x${sz}/apps/d2r.png" 2>/dev/null || true
            fi
        done
    fi
    rm -f "$TMP_ICO"
fi

ICON_PATH="$ICON_BASE/256x256/apps/d2r.png"
if [ ! -f "$ICON_PATH" ]; then
    ICON_PATH=""
fi

# Update icon cache
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache "$ICON_BASE" 2>/dev/null || true
fi

# Enable RememberAccountName in Battle.net config for persistent login
BNET_CONFIG="$BNET_PREFIX/pfx/drive_c/users/steamuser/AppData/Roaming/Battle.net/Battle.net.config"
if [ -f "$BNET_CONFIG" ]; then
    python3 -c "
import json
with open('$BNET_CONFIG', 'r') as f:
    cfg = json.load(f)
if cfg.get('Client', {}).get('RememberAccountName') != 'true':
    cfg.setdefault('Client', {})['RememberAccountName'] = 'true'
    with open('$BNET_CONFIG', 'w') as f:
        json.dump(cfg, f, indent=4)
    print('  Enabled RememberAccountName')
" 2>/dev/null || true
fi

# Use the Arc workaround launcher if it exists
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
Icon=${ICON_PATH:-applications-games}
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

# Copy to ~/Desktop for desktop icon (GNOME) and mark trusted
if [ -d "$HOME/Desktop" ]; then
    cp "$DESKTOP_FILE" "$HOME/Desktop/d2r.desktop"
    chmod +x "$HOME/Desktop/d2r.desktop"
    gio set "$HOME/Desktop/d2r.desktop" metadata::trusted true 2>/dev/null || true
    echo "  ~/Desktop/d2r.desktop (trusted)"
fi

# Register with desktop database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

echo "=== [05] Created ==="
echo "  $LAUNCH_SCRIPT        — Launch D2R via Battle.net"
echo "  $DIRECT_SCRIPT        — Launch D2R.exe directly (edit D2R_EXE_PATH)"
echo "  $DESKTOP_FILE"
if [ -n "$ICON_PATH" ]; then echo "  Icon: $ICON_PATH"; fi
echo ""
echo "If D2R fails on Intel Arc (black screen/crash), run:"
echo "  06-apply-arc-workarounds.sh"
