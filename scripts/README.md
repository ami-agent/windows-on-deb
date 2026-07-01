# Technical Implementation

## Architecture

```
scripts/                        # numbered = dependency order
├── 01-system-deps.sh           # apt packages, Vulkan, render group
├── 02-install-steam.sh         # Steam apt install
├── 03-install-proton.sh        # GE-Proton download + extract
├── 04-install-battlenet.sh     # Battle.net installer via Proton
├── 05-create-launcher-example.sh       # launch scripts + .desktop
├── 06-dev-toolchain-example.sh         # d2r-trainer build
└── config.env                  # shared paths sourced by every script
```

### How Proton Runs Windows Executables

Proton is a wrapper around Wine with DXVK/VKD3D, Steam runtime integration,
and prefix management. The key environment variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `STEAM_COMPAT_DATA_PATH` | Root of the Wine prefix directory | `~/Games/battlenet-prefix` |
| `STEAM_COMPAT_CLIENT_INSTALL_PATH` | Steam installation root | `~/.steam/root` |
| `WINEPREFIX` | (Set internally by Proton) | points to `<DATA_PATH>/pfx/` |

When `proton run <exe> [args]` is called it:

1. **`setup_prefix()`** — checks `pfx/version` against `CURRENT_PREFIX_VERSION`.
   If missing or mismatch, recreates prefix from GE-Proton's `default_pfx/`
   template (which includes clean registry, system DLLs, Wine Mono).
   Uses `pfx.lock` (FileLock) to guard against concurrent creation.
2. **`migrate_user_paths()`** — creates symlinks from WinXP-style paths
   (`Application Data`, `Local Settings`, `My Documents`) to Vista+ paths
   (`AppData/Roaming`, `AppData/Local`, `Documents`).
3. **`update_builtin_libs()`** — copies/re-links builtin DLLs from
   GE-Proton's `files/lib/wine/` into the prefix.
4. **Launches** the target EXE via Wine/Linux binary execution.

### Prefix Lifecycle

```
STEAM_COMPAT_DATA_PATH = ~/Games/battlenet-prefix/
├── version               # CURRENT_PREFIX_VERSION (e.g. GE-Proton11-1)
├── config_info           # cached prefix parameters (fonts dir, lib dir, etc.)
├── tracked_files         # list of files Proton placed (for upgrade cleanup)
├── pfx.lock              # FileLock for concurrent access
└── pfx/                  # the actual Wine prefix
    ├── system.reg        # HKLM registry
    ├── user.reg          # HKCU registry
    ├── userdef.reg       # default user registry
    ├── .update-timestamp
    ├── dosdevices/       # c: -> ../drive_c, z: -> /
    └── drive_c/          # C:\ drive
        ├── windows/
        ├── Program Files (x86)/
        │   ├── Battle.net/
        │   │   └── Battle.net Launcher.exe
        │   └── Diablo II Resurrected/
        │       └── D2R.exe
        └── users/
            └── steamuser/
                └── AppData/
                    ├── Local/Battle.net/
                    │   ├── BrowserCaches/    # CEF webview: cookies, session
                    │   │   ├── common/       # shared auth cookies
                    │   │   └── <id>/         # per-user profile
                    │   ├── CachedData.db     # login_cache table (SQLite)
                    │   └── Account/<id>/account.db
                    └── Roaming/Battle.net/
                        └── Battle.net.config # launcher preferences
```

### Login State Persistence

Battle.net auth is stored across three locations inside the prefix:

1. **BrowserCaches/common/Network/Cookies** (SQLite) — OAuth tokens:
   `auth.permit.*`, `remember.auth.permit.*`, `web.id`. Persistent cookies
   with 1-year expiry.
2. **CachedData.db** (SQLite) — `login_cache` table: battle tag, account ID,
   connected regions.
3. **Battle.net.config** (JSON) — `RememberAccountName` flag (set to `true`
   by `05-create-launcher-example.sh`).

**Why login was lost before the fix:**
`killall -9 ... wineserver` (SIGKILL) terminates the Wine server without
flushing LevelDB write-ahead logs in `BrowserCaches/`. On next launch,
Proton's `setup_prefix()` detects an inconsistent prefix state and may
reinitialize it, wiping the CEF cookie store. The browser session is
recreated without saved cookies, forcing re-authentication.

**Fix:** Remove SIGKILL; let Wine shut down cleanly via normal process
termination. The launcher scripts no longer contain any `killall -9` calls.

### GPU Spoofing for Intel Arc A770

D2R checks GPU capabilities at startup. The Mesa ANV Vulkan driver is
not recognized as capable, causing a black screen or crash. Workaround
applied via `dxvk.conf` placed in both battlenet and D2R directories:

```
dxgi.customDeviceId = 10de    # NVIDIA vendor
dxgi.customVendorId = 1b80    # GTX 1080 device
d3d12.maxResourceHeapSize = 2147483648
```

Additional environment variables baked into `launch-d2r-arc.sh`:

| Variable | Value | Purpose |
|----------|-------|---------|
| `DXVK_NVAPI_DRIVER_VERSION` | `46091` | Spoof NVIDIA driver version |
| `VKD3D_FEATURE_LEVEL` | `12_0` | Force DX12 feature level |
| `VKD3D_CONFIG` | `no_upload_hvv` | Disable host-visible-vram upload |
| `WINE_SIMULATE_WRITECOPY` | `1` | Fix blank Battle.net login window |
| `PROTON_USE_NTSYNC` | `1` | Use ntsync for better performance |

The `launch-d2r.sh` base script also includes `WINE_SIMULATE_WRITECOPY`
and `PROTON_USE_NTSYNC` but omits the DXVK/VKD3D overrides.

### Desktop Entry

```
~/.local/share/applications/d2r.desktop
~/Desktop/d2r.desktop (trusted via gio set metadata::trusted true)
```

The desktop entry has two actions:
- Default (double-click): Exec `launch-d2r-arc.sh` — full Arc workaround path
- Right-click → "Launch Battle.net Launcher": Exec `launch-d2r.sh` — base path

The icon is extracted from `D2R.exe` at setup time via `wrestool` → `icotool`.

---

### Per-Script Notes

**01-system-deps.sh**
Installs: mesa-vulkan-drivers, libvulkan1:i386, flatpak, winetricks,
mangohud, vulkan-tools, icoutils, acl. Adds user to `render` group.

**02-install-steam.sh**
`apt install steam-installer`. Steam provides the runtime libraries
(steam-runtime) that Proton depends on, even when running outside Steam.

**03-install-proton.sh**
Downloads GE-Proton11-1 tarball from GitHub, extracts to
`~/.steam/root/compatibilitytools.d/GE-Proton11-1/`. Aarch64 detection
exits early on non-x86_64 hosts.

**04-install-battlenet.sh**
Creates prefix via `STEAM_COMPAT_DATA_PATH` + `proton run`, downloads
Battle.net-Setup.exe with `wget`, installs via `proton run`. Sets
Windows version to 10 in the registry.

**05-create-launcher-example.sh**
Generates three launcher scripts + desktop entry. Sets
`RememberAccountName=true` in `Battle.net.config` via Python `json` module.
Extracts D2R icon for desktop use.

**06-dev-toolchain-example.sh**
Clones and builds d2r-trainer. Requires `libc6-dev-i386` for 32-bit cross
compilation. Installs Python dependencies for cheat-engine-like memory
scanning.
