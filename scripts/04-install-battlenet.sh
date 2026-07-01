#!/bin/bash
set -euo pipefail

echo "=== [04] Installing Battle.net ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

detect_ge_proton

BNET_INSTALLER="$HOME/Downloads/Battle.net-Setup.exe"

if [ -f "$BNET_INSTALLER" ]; then
    echo "Installer already downloaded: $BNET_INSTALLER"
else
    echo "Downloading Battle.net installer..."
    wget -O "$BNET_INSTALLER" \
        "https://www.battle.net/download/getInstallerForGame?os=win&version=LIVE&gameProgram=BATTLENET_APP"
fi

mkdir -p "$GAMES_DIR" "$BNET_PREFIX" "$D2R_DATA_DIR"

RUN_SCRIPT="$GAMES_DIR/run-battlenet.sh"
cat > "$RUN_SCRIPT" << SCRIPTEOF
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
source "\$SCRIPT_DIR/scripts/config.env" 2>/dev/null || source "\$(dirname "\$0")/config.env" 2>/dev/null || true
: "\${GE_PROTON_DIR:=$GE_PROTON_DIR}"
: "\${BNET_PREFIX:=$BNET_PREFIX}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="\$HOME/.steam/root"
export STEAM_COMPAT_DATA_PATH="\$BNET_PREFIX"
export WINE_SIMULATE_WRITECOPY=1
export PROTON_USE_NTSYNC=1
exec "\$GE_PROTON_DIR/proton" run "\$@"
SCRIPTEOF
chmod +x "$RUN_SCRIPT"

echo ""
echo "============================================================"
echo " Running Battle.net installer via GE-Proton..."
echo "============================================================"
echo ""
echo "When the installer opens:"
echo "  1. Install Battle.net (default path is fine)"
echo "  2. When Battle.net launches afterward:"
echo "     a. Settings -> General -> UNCHECK 'Use hardware acceleration'"
echo "     b. Settings -> Game Install/Update -> change path to:"
echo "        $D2R_DATA_DIR"
echo "     c. Install Diablo II: Resurrected"
echo "============================================================"
echo ""

"$RUN_SCRIPT" "$BNET_INSTALLER"

# After prefix creation, set Windows version to 10 (D2R requirement)
echo "Setting Windows version to 10 in the Proton prefix..."
WINEPREFIX="$BNET_PREFIX/pfx" \
WINE="$GE_PROTON_DIR/files/bin/wine" \
WINESERVER="$GE_PROTON_DIR/files/bin/wineserver" \
"$GE_PROTON_DIR/files/bin/wine" reg add "HKEY_CURRENT_USER\Software\Wine" /v Version /d win10 /f 2>/dev/null || true

echo ""
echo "=== [04] Complete ==="
echo "After D2R finishes installing through Battle.net, run:"
echo "  05-create-launcher.sh"
