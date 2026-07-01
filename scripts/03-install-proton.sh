#!/bin/bash
set -euo pipefail

echo "=== [03] Installing GE-Proton ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.env"

if find_ge_proton; then
    echo "GE-Proton already installed: $GE_PROTON_DIR"
    exit 0
fi

if [ ! -d "$STEAM_ROOT" ]; then
    echo "ERROR: $STEAM_ROOT does not exist."
    echo "Run Steam at least once first: steam &"
    exit 1
fi

mkdir -p "$COMPAT_TOOLS_DIR"

# Fetch latest release info from GitHub API
echo "Fetching latest GE-Proton release info..."
JSON=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest)

# Parse JSON with python3 to find the x86_64 tarball asset URL
echo "Identifying x86_64 release asset..."
DOWNLOAD_URL=$(echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data['assets']:
    name = a['name']
    if name.endswith('.tar.gz') and 'aarch64' not in name:
        print(a['browser_download_url'])
        break
")

if [ -z "$DOWNLOAD_URL" ]; then
    echo "ERROR: Could not find x86_64 GE-Proton release in GitHub API response."
    echo "Response:"
    echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets', []):
    print(f\"  {a['name']}\")
"
    exit 1
fi

echo "Downloading: $DOWNLOAD_URL"
TARBALL="/tmp/GE-Proton.tar.gz"
curl -L -o "$TARBALL" "$DOWNLOAD_URL"

# Determine extracted directory name from the tarball filename
TAR_NAME=$(basename "$DOWNLOAD_URL")
DIR_NAME="${TAR_NAME%.tar.gz}"
echo "Expected directory: $DIR_NAME"

echo "Extracting to $COMPAT_TOOLS_DIR..."
tar -xzf "$TARBALL" -C "$COMPAT_TOOLS_DIR"

rm "$TARBALL"

# Verify extraction
if [ ! -d "$COMPAT_TOOLS_DIR/$DIR_NAME" ]; then
    echo "ERROR: Extraction failed — $COMPAT_TOOLS_DIR/$DIR_NAME not found."
    ls "$COMPAT_TOOLS_DIR/"
    exit 1
fi

if [ ! -f "$COMPAT_TOOLS_DIR/$DIR_NAME/proton" ]; then
    echo "ERROR: $COMPAT_TOOLS_DIR/$DIR_NAME/proton not found after extraction."
    exit 1
fi

GE_PROTON_DIR="$COMPAT_TOOLS_DIR/$DIR_NAME"
echo "GE-Proton installed: $GE_PROTON_DIR"

echo ""
echo "=== [03] Complete ==="
echo "Next: run 04-install-battlenet.sh"
