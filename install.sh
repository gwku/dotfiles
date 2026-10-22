#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(uname -s)"
if [[ -z "$HOST" ]]; then
  echo "usage: ./install.sh <hostname>" >&2
  exit 1
fi
cd "$REPO_ROOT"
FLAKE_REF="path:${REPO_ROOT}"

sudo_keepalive_pid=""
cleanup() {
  if [[ -n "$sudo_keepalive_pid" ]]; then
    kill "$sudo_keepalive_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ "$PLATFORM" == Darwin ]]; then
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Xcode command-line tools are required. Starting Apple's installer..."
    xcode-select --install
    echo "Finish that installation, then rerun ./install.sh ${HOST}." >&2
    exit 1
  fi

  # Front-load administrator authentication and keep it alive through the
  # Nix installation so the later switch cannot prompt again.
  echo "Authenticating with macOS administrator privileges..."
  sudo -v
  (
    while true; do
      sudo -n true
      sleep 50
    done
  ) &
  sudo_keepalive_pid="$!"
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Determinate Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

case "$PLATFORM" in
  Darwin)
    EXPECTED_USER="$(nix --extra-experimental-features 'nix-command flakes' \
      eval --raw "${FLAKE_REF}#darwinConfigurations.${HOST}.config.system.primaryUser")"
    if ! id "$EXPECTED_USER" >/dev/null 2>&1; then
      echo "Configured macOS user '${EXPECTED_USER}' does not exist." >&2
      echo "Create/use that short account name before bootstrapping." >&2
      exit 1
    fi
    if [[ "$USER" != "$EXPECTED_USER" ]]; then
      echo "Run this installer while logged in as '${EXPECTED_USER}', not '${USER}'." >&2
      exit 1
    fi

    "${REPO_ROOT}/scripts/switch.sh" "$HOST"
    ;;
  Linux)
    "${REPO_ROOT}/scripts/switch.sh" "$HOST"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac
