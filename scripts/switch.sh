#!/usr/bin/env bash
# Front-load interactive authentication, then run an unattended switch.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM="$(uname -s)"
HOST="${1:-}"

case "$PLATFORM" in
  Darwin)
    HOST="${HOST:-gkmp}"
    # Opt out before nix-darwin invokes Homebrew, including the first switch
    # before the declarative shell environment has been activated.
    export HOMEBREW_NO_ANALYTICS=1
    ;;
  Linux) HOST="${HOST:-workstation}" ;;
  *)
    echo "Unsupported platform: $PLATFORM" >&2
    exit 1
    ;;
esac

if command -v nix >/dev/null 2>&1; then
  NIX_BIN="$(command -v nix)"
elif [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
else
  echo "Nix is not installed. Run ./install.sh ${HOST} first." >&2
  exit 1
fi

find_user_command() {
  local name="$1"
  local resolved=""
  local candidate=""

  if resolved="$(command -v "$name" 2>/dev/null)"; then
    printf '%s\n' "$resolved"
    return 0
  fi

  for candidate in \
    "/etc/profiles/per-user/${USER}/bin/${name}" \
    "${HOME}/.nix-profile/bin/${name}" \
    "/run/current-system/sw/bin/${name}" \
    "/opt/homebrew/bin/${name}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

sudo_keepalive_pid=""
cleanup() {
  if [[ -n "$sudo_keepalive_pid" ]]; then
    kill "$sudo_keepalive_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ "$PLATFORM" == Darwin ]]; then
  echo "==> Authenticating with macOS administrator privileges"
  if ! sudo -n true 2>/dev/null; then
    sudo -v
  fi

  # Keep the initial authorization alive so a long build cannot ask again.
  (
    while true; do
      sudo -n true
      sleep 50
    done
  ) &
  sudo_keepalive_pid="$!"
fi

BW_BIN="$(find_user_command bw || true)"
BW_SSH_SYNC_BIN="$(find_user_command bw-ssh-sync || true)"
JQ_BIN="$(find_user_command jq || true)"

if [[ -n "$BW_BIN" && -n "$BW_SSH_SYNC_BIN" && -n "$JQ_BIN" ]]; then
  bw_status="$("$BW_BIN" status | "$JQ_BIN" -er '.status')"
  case "$bw_status" in
    unlocked | locked)
      echo "==> Synchronizing Bitwarden SSH metadata"
      # A locked CLI prompts here, before the long build starts.
      "$BW_SSH_SYNC_BIN"
      ;;
    unauthenticated)
      echo "==> Bitwarden CLI is not logged in; SSH metadata sync will be skipped"
      ;;
    *)
      echo "Unexpected Bitwarden CLI status: $bw_status" >&2
      exit 1
      ;;
  esac
else
  echo "==> Bitwarden CLI is not available yet; SSH metadata sync will be skipped"
fi

cd "$REPO_ROOT"

case "$PLATFORM" in
  Darwin)
    echo "==> Applying nix-darwin configuration for host: $HOST"
    sudo -n "$NIX_BIN" run \
      --extra-experimental-features 'nix-command flakes' \
      "path:.#darwin-rebuild" -- switch --flake "path:.#${HOST}"
    ;;
  Linux)
    echo "==> Applying standalone Home Manager configuration for host: $HOST"
    "$NIX_BIN" run \
      --extra-experimental-features 'nix-command flakes' \
      "path:.#home-manager" -- switch --flake "path:.#${USER}@${HOST}"
    ;;
esac
