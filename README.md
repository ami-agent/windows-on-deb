# windows-on-deb

Bootstraps a full Windows-gaming-on-Debian environment — system deps, Steam,
GE-Proton (with Wine), Battle.net launcher, and per-app runner scripts.

Diablo II: Resurrected is the reference end-application; the pattern applies
to any Windows game distributed through Battle.net, Steam, or standalone.

Tested on:

| Distro | GPU | Driver | Display Server | Stack Version | Status |
|--------|-----|--------|----------------|---------------|--------|
| Ubuntu 24.04 | Intel Arc A770 | Mesa ANV (24.0.x) | Wayland | GE-Proton11-1 | ✓ Full stack |
| | | | | | |
| | | | | | |

## Scripts

Run in order:

| Step | Script | Layer | Sudo? |
|------|--------|-------|-------|
| 1 | `01-system-deps.sh` | Vulkan drivers, 32-bit libs, Flatpak, Winetricks, icoutils, mangohud | Yes |
| 2 | `02-install-steam.sh` | Steam + Steam runtime | Yes |
| 3 | `03-install-proton.sh` | GE-Proton (downloaded into Steam's compatibilitytools.d) | No |
| 4 | `04-install-battlenet.sh` | Battle.net launcher under GE-Proton prefix | No |
| 5 | `05-create-launcher.sh` | Launch scripts + desktop entry (applies to any installed game) | No |
| 6 | `07-dev-toolchain.sh` | d2r-trainer (Linux memory trainer) + dev tools | Partial |

## Quick Start

```bash
cd ~/Projects/windows-on-deb/scripts
chmod +x *.sh
./01-system-deps.sh
./02-install-steam.sh
# Launch Steam once: steam &
./03-install-proton.sh
./04-install-battlenet.sh
# Install D2R through Battle.net, then:
./05-create-launcher.sh
./07-dev-toolchain.sh
```

Output lands in `~/Games/`:

| File | Purpose |
|------|---------|
| `~/Games/launch-d2r.sh` | Launch via Battle.net (`--exec="launch OSI"`) |
| `~/Games/launch-d2r-arc.sh` | Same with Intel Arc env vars + ACL fix |
| `~/Games/launch-d2r-direct.sh` | Direct D2R.exe launch (broken — needs auth) |
| `~/.local/share/applications/d2r.desktop` | Desktop entry (also on Desktop) |

## Using for Another Game

1. Steps 1–3 are one-time — they install the stack.
2. Create a new GE-Proton prefix for your app:
   ```bash
   export STEAM_COMPAT_DATA_PATH="$HOME/Games/my-prefix"
   export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/root"
   ~/.steam/root/compatibilitytools.d/GE-Proton*/proton run ./installer.exe
   ```
3. Write a launcher script (copy `launch-d2r.sh` as a template) with `--exec="launch <product>"`.

## Layout

```
~/.steam/root/compatibilitytools.d/GE-Proton*/   # GE-Proton (Wine + DXVK + VKD3D)
~/Games/
├── battlenet-prefix/          # Wine prefix (GE-Proton)
│   └── pfx/drive_c/Program Files (x86)/Battle.net/
├── D2R/                       # D2R game data (~30 GB)
├── launch-d2r.sh              # Launch via Battle.net
├── launch-d2r-direct.sh       # Direct D2R.exe launch (broken)
└── launch-d2r-arc.sh          # Arc workaround wrapper
```

## References

- [Battle.net on Linux: What Works in 2026](https://sudowheel.com/battlenet-linux.html)
- [D2R Memory Trainer (Linux)](https://github.com/axiom0x0/d2r-trainer)
- [D2R Horadric Tools](https://github.com/crabsmadethis/d2r-horadric-tools)
- [GE-Proton Releases](https://github.com/GloriousEggroll/proton-ge-custom/releases)
