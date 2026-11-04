#!/usr/bin/env bash
# Start the official tray front end of the existing daemon, without enrollment.
set -euo pipefail
[[ $(uname -s) == Linux ]] || { printf 'Linux only\n' >&2; exit 1; }
client=$(command -v tailscale)
"$client" systray --help >/dev/null 2>&1
# The GUI is per desktop user, never root. Preserve daemon preferences/identity.
[[ $EUID -ne 0 ]] || { printf 'Run as your graphical desktop user, without sudo\n' >&2; exit 1; }
unitdir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$unitdir"
# Replace the official default.target autostart if configured previously. This
# avoids starting under user linger before a graphical session exists.
systemctl --user disable tailscale-systray.service >/dev/null 2>&1 || true
cat > "$unitdir/tailscale-systray.service" <<UNIT
[Unit]
Description=Tailscale system tray controller
Documentation=https://tailscale.com/docs/features/client/linux-systray
After=graphical-session.target dbus.service
PartOf=graphical-session.target

[Service]
ExecStart=$client systray
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
UNIT
systemctl --user daemon-reload
systemctl --user enable tailscale-systray.service
if systemctl --user --quiet is-active graphical-session.target; then
  systemctl --user start tailscale-systray.service
  printf 'Tailscale tray ready in your graphical session; daemon identity unchanged\n'
else
  printf 'Tailscale tray enabled for the next graphical session\n'
fi
printf 'If controls are read-only, run once: sudo tailscale set --operator=%s\n' "$(id -un)"
