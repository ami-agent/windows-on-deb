# Gaming-on-Debian Stack: Steam + Proton + Battle.net

Bootstraps a full Windows-gaming-on-Debian environment — system deps, Steam,
GE-Proton (with Wine), Battle.net launcher, and per-app runner scripts.

Diablo II: Resurrected is the reference end-application; the pattern applies
to any Windows game distributed through Battle.net, Steam, or standalone.

## Stack

| Step | Script | Layer | Sudo? |
|------|--------|-------|-------|
| 1 | `01-system-deps.sh` | Vulkan drivers, 32-bit libs, Flatpak, Winetricks, icoutils, mangohud | Yes |
| 2 | `02-install-steam.sh` | Steam + Steam runtime | Yes |
| 3 | `03-install-proton.sh` | GE-Proton (downloaded into Steam's compatibilitytools.d) | No |
| 4 | `04-install-battlenet.sh` | Battle.net launcher under GE-Proton prefix | No |
| 5 | `05-create-launcher.sh` | Launch scripts + desktop entry (applies to any installed game) | No |
| 6 | `06-apply-arc-workarounds.sh` | GPU spoofing (dxvk.conf) + Arc-specific launch wrapper | No |
| 7 | `07-dev-toolchain.sh` | d2r-trainer (Linux memory trainer) + dev tools | Partial |

## Quick Start

```bash
cd ~/scripts
chmod +x *.sh
./01-system-deps.sh
./02-install-steam.sh
# Launch Steam once: steam &
./03-install-proton.sh
./04-install-battlenet.sh
# Install D2R through Battle.net, then:
./05-create-launcher.sh
./06-apply-arc-workarounds.sh
./07-dev-toolchain.sh
```

## Using for Another Game

1. Steps 1–3 are one-time — they install the stack.
2. Create a new GE-Proton prefix for your app:
   ```bash
   export STEAM_COMPAT_DATA_PATH="$HOME/Games/my-prefix"
   export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/root"
   ~/.steam/root/compatibilitytools.d/GE-Proton*/proton run ./installer.exe
   ```
3. Write a launcher script (copy `launch-d2r.sh` as a template) with `--exec="launch <product>"`.

## Troubleshooting

- **White Battle.net window**: Disable hardware acceleration in Battle.net settings
- **BLZBNTBNA00000005 login error**: `rm -rf ~/Games/battlenet-prefix/pfx/drive_c/ProgramData/Battle.net`
- **D2R black screen/crash**: Use `launch-d2r-arc.sh` (GPU spoofing for Intel Arc)
- **Blank login window**: `WINE_SIMULATE_WRITECOPY=1` must be set
- **D2R.exe not found in /proc**: PE base is under `memfd:wine-mapping` on Proton
- **Login resets every launch**: `killall -9 ... wineserver` corrupts prefix state; use `wineserver -k` instead

## Filesystem Layout

```
~/.steam/root/compatibilitytools.d/GE-Proton*/   # GE-Proton (Wine + DXVK + VKD3D)
~/Games/
├── battlenet-prefix/          # Wine prefix (GE-Proton)
│   └── pfx/drive_c/Program Files (x86)/Battle.net/
├── D2R/                       # D2R game data (~30 GB)
├── launch-d2r.sh              # Launch via Battle.net (--exec="launch OSI")
├── launch-d2r-direct.sh       # Launch D2R.exe directly (broken — needs auth)
└── launch-d2r-arc.sh          # Arc workaround wrapper (ACL + env vars + exec)
```

## References

- [Battle.net on Linux: What Works in 2026](https://sudowheel.com/battlenet-linux.html)
- [D2R Memory Trainer (Linux)](https://github.com/axiom0x0/d2r-trainer)
- [D2R Horadric Tools](https://github.com/crabsmadethis/d2r-horadric-tools)
- [GE-Proton Releases](https://github.com/GloriousEggroll/proton-ge-custom/releases)
