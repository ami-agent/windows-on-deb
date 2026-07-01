# windows-on-deb

Battle.net + Diablo II: Resurrected on Ubuntu 24.04 via GE-Proton.

Target: Intel Arc A770 / Mesa ANV / Wayland.

```
scripts/
├── 01-system-deps.sh         apt packages, Vulkan, render group       [sudo]
├── 02-install-steam.sh        Steam + Proton runtime                   [sudo]
├── 03-install-proton.sh       GE-Proton auto-download (x86_64)
├── 04-install-battlenet.sh    Battle.net installer + prefix setup
├── 05-create-launcher.sh      D2R launch scripts
├── 06-apply-arc-workarounds.sh  Intel Arc GPU spoofing fixes
├── 07-dev-toolchain.sh        d2r-trainer + memory access setup       [sudo]
├── 08-fix-render-d2r.sh       Fix Vulkan render + Win10 mode          [sudo]
└── config.env                 shared paths
```

Run numbered scripts in order. Scripts 01, 02, 07, 08 need sudo.
