# Tailscale connection controls

The GUI talks to the existing daemon socket and preserves its enrollment.
Controller URLs, mesh addresses, and device inventory belong in private files.
No new VPN backend, keys, profiles, or authentication are needed.

## macOS

Use **Tailscale Menu**, the official open-source Tailscale `cmd/systray`
application built from the same source/version as the nixpkgs package. It appears
in the menu bar and offers Connect/Disconnect, current account/device details,
IP copying, exit-node selection, and a link to the local web settings page.
Exit-node selection is empty while this mesh has no exit node.

`modules/home/tailscale-gui.nix` installs the app and a per-user LaunchAgent.
`packages/tailscale-systray/default.nix` builds the upstream source with CGO and
packages an application bundle. The current lock resolves version 1.98.0.
The agent uses `/var/run/tailscaled.socket` and runs as the desktop user.
Quitting this menu app leaves the VPN connected. Open **Tailscale Menu** again
from Applications/Home Manager Apps, or restart its agent:

```sh
launchctl kickstart gui/$(id -u)/org.nix-community.home.tailscale-menu
```

The official systray is beta and officially supported on Linux. Tailscale
explicitly documents building/running it on macOS; some features, such as desktop
notifications, may be unavailable. This menu is a front end for our existing
boot-time Nix daemon. The separately distributed **Tailscale.app** uses its own
network/system-extension backend and does not attach to that daemon. Do not
install/start it alongside this setup without an intentional migration.

## Linux / CachyOS

The official Linux client includes `tailscale systray`. It uses the existing
system `tailscaled`, so the Lenovo keeps its original identity and routing.
Waybar's tray supports its StatusNotifierItem menu; `wl-clipboard` is installed
for copying addresses. The GUI module also declares `pkgs.tailscale` itself,
without depending on a T3 module to supply it.

Home Manager starts the per-user `tailscale-systray` service with
`graphical-session.target`; it stops with that session. It does not start under
user linger before a desktop exists. Hyprland on this Lenovo already activates
that target and imports `WAYLAND_DISPLAY`/`XDG_CURRENT_DESKTOP` into systemd and
D-Bus, which the tray needs.

For the current native CachyOS installation without Nix, reproduce the user
service with:

```sh
./scripts/install-tailscale-gui-linux.sh
systemctl --user status tailscale-systray
```

Run this as the actual desktop user, without sudo. It creates a user service
using the installed `tailscale` binary; it does not install packages, restart the
VPN daemon, or enroll a device. It starts the tray immediately only when a
graphical session target is active. To stop its startup:
`systemctl --user disable --now tailscale-systray`.

## Permissions and administration

GUI connection controls require the local user to be the daemon's operator.
For each machine, set its actual desktop user as operator once after enrollment:

```sh
sudo tailscale set --operator="$USER"
```

Use `tailscale set`, which preserves unrelated preferences and the Headscale
control URL. Do not use logout, reset state, or authenticate against the public
Tailscale service just to install a GUI.

The menu's **More settings** link opens the built-in device web interface.
Headscale does not implement every Tailscale control-plane web-management API,
so this page may offer only device information. Local native Connect/Disconnect
and exit-node controls use the daemon API directly and do not depend on that web
login. Use the homelab **Headplane** page for mesh administration.

Validated on all three laptops: the menus run against existing daemons; original
node IDs/IPs and control URL are unchanged; desktop operators have read/write
LocalAPI permission (tested by reapplying the existing `WantRunning=true` value,
without disconnecting). Lenovo's D-Bus menu shows Connected, an enabled
Disconnect action, the Headscale account, and its current device address.

Sources:

- [Official systray, including macOS build instructions](https://tailscale.com/docs/features/client/linux-systray)
- [macOS variants and daemon distinction](https://tailscale.com/docs/concepts/macos-variants)
- [Upstream official systray source](https://github.com/tailscale/tailscale/tree/main/cmd/systray)
- [Device web interface](https://tailscale.com/kb/1325/device-web-interface)
