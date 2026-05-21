# Unmanaged macOS apps

Apps not in nixpkgs for `aarch64-darwin` (or where the upstream installer is the only realistic distribution channel). Install these by hand after the first `darwin-rebuild switch` lands.

| App | Why | Download |
|---|---|---|
| OrbStack | Docker / Linux VMs on macOS — preferred over Docker Desktop. Not in nixpkgs. | https://orbstack.dev |
| Raycast | Spotlight replacement + extensions. Not in nixpkgs darwin. | https://www.raycast.com |
| Rectangle | Window snapping. | https://rectangleapp.com |
| JetBrains Toolbox | Manages all JetBrains IDEs. Toolbox itself isn't packaged. | https://www.jetbrains.com/toolbox-app |
| 1Password (GUI) | Mac app for the vault; CLI `_1password` is fine via Nix. | https://1password.com/downloads/mac |
| Signal | Sandboxed install only on darwin; nixpkgs has Linux only. | https://signal.org/download/macos |
| Zoom | Pinned to vendor installer for AV compatibility. | https://zoom.us/download |

If something here later shows up in nixpkgs for darwin (`nix search nixpkgs <name>`), move it into [`modules/darwin/apps.nix`](modules/darwin/apps.nix) and delete the row.

## Login items / system services that aren't config-managed

- **OrbStack** — start on login (set in OrbStack preferences).
- **Raycast** — start on login, hotkey `cmd+space` (after disabling Spotlight's).
- **1Password** — SSH agent + system auth integration.

These are not declarative on macOS without third-party modules (e.g. `home-manager` `launchd` services), so configure them via each app's preferences.
