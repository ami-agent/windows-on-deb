# windows-on-deb

Get Windows games running on Debian/Ubuntu. These scripts set up everything
you need — system dependencies, Steam, GE-Proton (Wine + DXVK + VKD3D),
and launcher scripts for each game.

We use Diablo II: Resurrected through Battle.net as the example, but the
same setup works for any Windows game, whether it's on Battle.net, Steam,
or standalone.

Tested on:

| Distro | GPU | Driver | Display Server | Stack Version | Status |
|--------|-----|--------|----------------|---------------|--------|
| Ubuntu 24.04 | Intel Arc A770 | Mesa ANV (24.0.x) | Wayland | GE-Proton11-1 | ✓ Working |
| | | | | | |
| | | | | | |

## Scripts

Run in order:

| Step | Script | What it does | Sudo? |
|------|--------|-------------|-------|
| 1 | `01-system-deps.sh` | Vulkan drivers, 32-bit libs, Flatpak, Winetricks, icoutils, mangohud | Yes |
| 2 | `02-install-steam.sh` | Steam + Steam runtime | Yes |
| 3 | `03-install-proton.sh` | Downloads GE-Proton into Steam's compat tools dir | No |
| 4 | `04-install-battlenet.sh` | Installs Battle.net under a GE-Proton prefix | No |
| 5 | `05-create-launcher-example.sh` | Creates launch scripts + desktop shortcut | No |
| 6 | `06-dev-toolchain-example.sh` | Builds d2r-trainer (memory scanner for D2R) | Partial |

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
./05-create-launcher-example.sh
./06-dev-toolchain-example.sh
```

Everything ends up in `~/Games/`:

| File | What it's for |
|------|---------------|
| `~/Games/launch-d2r.sh` | Launches D2R through Battle.net |
| `~/Games/launch-d2r-arc.sh` | Same but with fixes for Intel Arc GPUs |
| `~/Games/launch-d2r-direct.sh` | Tries to launch D2R.exe directly (doesn't work, needs auth) |
| `~/.local/share/applications/d2r.desktop` | Desktop shortcut |

## Using for Another Game

Steps 1-3 only need to run once — they set up the base stack. After that:

1. Create a new prefix for your game:
   ```bash
   export STEAM_COMPAT_DATA_PATH="$HOME/Games/my-prefix"
   export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.steam/root"
   ~/.steam/root/compatibilitytools.d/GE-Proton*/proton run ./installer.exe
   ```
2. Write a launcher script (copy `launch-d2r.sh` and tweak the `--exec` flag).

## Layout

```
~/.steam/root/compatibilitytools.d/GE-Proton*/   # GE-Proton (Wine + DXVK + VKD3D)
~/Games/
├── battlenet-prefix/          # Wine prefix (GE-Proton)
│   └── pfx/drive_c/Program Files (x86)/Battle.net/
├── D2R/                       # D2R game data (~30 GB)
├── launch-d2r.sh              # Launches D2R through Battle.net
├── launch-d2r-direct.sh       # Direct launch (doesn't work)
└── launch-d2r-arc.sh          # Arc-specific launcher
```

## References

- [Battle.net on Linux: What Works in 2026](https://sudowheel.com/battlenet-linux.html)
- [D2R Memory Trainer (Linux)](https://github.com/axiom0x0/d2r-trainer)
- [D2R Horadric Tools](https://github.com/crabsmadethis/d2r-horadric-tools)
- [GE-Proton Releases](https://github.com/GloriousEggroll/proton-ge-custom/releases)
