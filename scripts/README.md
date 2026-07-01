# Battle.net + Diablo II: Resurrected Setup Scripts

Run in order:

| Step | Script | Description | Sudo? |
|------|--------|-------------|-------|
| 1 | `01-system-deps.sh` | Install system packages (Vulkan, Flatpak, etc.) | Yes |
| 2 | `02-install-steam.sh` | Install Steam for Proton runtime | Yes |
| 3 | `03-install-proton.sh` | Install GE-Proton via ProtonUp-Qt | No |
| 4 | `04-install-battlenet.sh` | Install Battle.net launcher | No |
| 5 | `05-create-launcher.sh` | Create D2R launch scripts | No |
| 6 | `06-apply-arc-workarounds.sh` | Intel Arc GPU fixes (if needed) | No |
| 7 | `07-dev-toolchain.sh` | Build d2r-trainer + dev tools | Partial |

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

## Troubleshooting

- **White Battle.net window**: Disable hardware acceleration in Battle.net settings
- **BLZBNTBNA00000005 login error**: `rm -rf ~/Games/battlenet-prefix/pfx/drive_c/ProgramData/Battle.net`
- **D2R black screen/crash**: Use `launch-d2r-arc.sh` (applies GPU spoofing)
- **Blank login window**: Ensure `WINE_SIMULATE_WRITECOPY=1` is set
- **D2R.exe not found in /proc**: PE base is under `memfd:wine-mapping` on Proton

## Filesystem Layout

```
~/Games/
├── battlenet-prefix/          # Wine prefix (GE-Proton)
│   └── pfx/drive_c/Program Files (x86)/Battle.net/
├── D2R/                       # D2R game data (~30 GB)
├── launch-d2r.sh              # Launch via Battle.net
├── launch-d2r-direct.sh       # Launch D2R.exe directly
└── launch-d2r-arc.sh          # Launch with Arc workarounds
```

## References

- [Battle.net on Linux: What Works in 2026](https://sudowheel.com/battlenet-linux.html)
- [D2R Memory Trainer (Linux)](https://github.com/axiom0x0/d2r-trainer)
- [D2R Horadric Tools](https://github.com/crabsmadethis/d2r-horadric-tools)
- [GE-Proton Releases](https://github.com/GloriousEggroll/proton-ge-custom/releases)
