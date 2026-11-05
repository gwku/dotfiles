#!/usr/bin/env bash
# Enable desktop windows after graphical login, without enabling remote input.
set -euo pipefail
start=false
case "${1:-}" in
  '') ;;
  --start) start=true ;;
  *) echo 'Usage: install-linux-session-startup.sh [--start]' >&2; exit 2 ;;
esac
[[ $(uname -s) == Linux && $EUID -ne 0 ]] || {
  echo 'Run as the Linux desktop user.' >&2; exit 1;
}
[[ -x /usr/bin/rustdesk && -x "$HOME/.local/bin/t3code-desktop" ]] || {
  echo 'Install the native RustDesk and T3 desktop clients first.' >&2; exit 1;
}
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$units"
write_unit() {
  local name="$1" description="$2" command="$3" temporary
  temporary=$(mktemp)
  cat > "$temporary" <<EOF
[Unit]
Description=$description
PartOf=graphical-session.target
After=graphical-session-pre.target

[Service]
Type=simple
ExecStart=$command
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF
  if ! cmp -s "$temporary" "$units/$name"; then
    if [[ -e "$units/$name" ]]; then
      install -m 600 "$units/$name" "$units/$name.before-startup-$(date +%s%N)"
    fi
    install -m 644 "$temporary" "$units/$name"
  fi
  rm -f "$temporary"
}
write_unit rustdesk-gui.service 'RustDesk attended desktop window' /usr/bin/rustdesk
write_unit t3code-desktop.service 'T3 Code desktop client' '%h/.local/bin/t3code-desktop'
systemctl --user daemon-reload
systemctl --user enable rustdesk-gui.service t3code-desktop.service
if $start; then
  systemctl --user is-active --quiet graphical-session.target || {
    echo 'Log into a graphical session before using --start.' >&2; exit 1;
  }
  systemctl --user start rustdesk-gui.service t3code-desktop.service
fi
echo 'Graphical-login startup enabled. RustDesk still requires local approval.'
