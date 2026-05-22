#!/usr/bin/env bash
# Spin up a macOS VM via tart and validate the dotfiles inside it.
#
# Default flow (headless, automated):
#   1. Clone the macOS image if not already local.
#   2. Boot the VM headless in the background.
#   3. SSH in as admin/admin (via `nix run nixpkgs#sshpass`).
#   4. Install Nix inside the VM and run scripts/check.sh.
#   5. Leave the VM running so you can SSH in for manual follow-up.
#
# Flags:
#   --gui          Attach a window, skip the SSH automation.
#   --switch       Also run `darwin-rebuild switch` inside the VM after
#                  the check (full activation test).
#   --stop-after   Stop the VM when the script finishes.
#
# Env vars:
#   TART_IMAGE     OCI image (default: macos-tahoe-base:latest).
#   VM_NAME        Local VM name (default: dotfiles-test).
#   HOST_NAME      Flake host attribute (default: gkmp).

set -euo pipefail

IMAGE="${TART_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
VM_NAME="${VM_NAME:-dotfiles-test}"
HOST_NAME="${HOST_NAME:-gkmp}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="${TMPDIR:-/tmp}/tart-${VM_NAME}.log"

GUI=false
DO_SWITCH=false
STOP_AFTER=false
for arg in "$@"; do
  case "$arg" in
    --gui)        GUI=true ;;
    --switch)     DO_SWITCH=true ;;
    --stop-after) STOP_AFTER=true ;;
    --help|-h)    sed -n '2,/^$/p' "$0"; exit 0 ;;
    *)            echo "Unknown flag: $arg (use --help)" >&2; exit 1 ;;
  esac
done

command -v tart >/dev/null || {
  echo "tart not installed. Install it with:" >&2
  echo "  brew install cirruslabs/cli/tart" >&2
  exit 1
}

# Clone the image if no local VM by that name exists.
if ! tart list --format json 2>/dev/null | grep -q "\"Name\":\"${VM_NAME}\""; then
  echo "==> Cloning ${IMAGE} into local VM '${VM_NAME}' (one-time, ~30-40 GB)..."
  tart clone "$IMAGE" "$VM_NAME"
fi

if $GUI; then
  echo "==> Starting VM '${VM_NAME}' with GUI."
  echo "    Login: admin / admin"
  echo "    Repo mounted at: /Volumes/My Shared Files/dotfiles"
  exec tart run "$VM_NAME" --dir="dotfiles:$REPO_ROOT"
fi

# Need nix on the host for `nix run nixpkgs#sshpass`.
command -v nix >/dev/null || {
  echo "nix not on host PATH — source the daemon profile first:" >&2
  echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" >&2
  exit 1
}

# Boot the VM headless in the background.
echo "==> Starting VM '${VM_NAME}' headless (log: ${LOG_FILE})..."
nohup tart run "$VM_NAME" --dir="dotfiles:$REPO_ROOT" --no-graphics \
  > "$LOG_FILE" 2>&1 &
disown

# Cleanup hook for --stop-after.
cleanup() {
  if $STOP_AFTER; then
    echo "==> Stopping VM '${VM_NAME}'..."
    tart stop "$VM_NAME" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Wait for SSH on port 22.
echo "==> Waiting for VM to be SSH-reachable (up to 5 min)..."
IP=""
for _ in $(seq 1 60); do
  IP="$(tart ip "$VM_NAME" 2>/dev/null || true)"
  if [[ -n "$IP" ]] && nc -z "$IP" 22 2>/dev/null; then
    break
  fi
  sleep 5
done
if [[ -z "$IP" ]] || ! nc -z "$IP" 22 2>/dev/null; then
  echo "VM did not become SSH-reachable in 5 minutes." >&2
  echo "Check the log: tail -30 ${LOG_FILE}" >&2
  exit 1
fi
echo "    VM up at ${IP}"

SSHPASS=(nix --extra-experimental-features 'nix-command flakes' run nixpkgs#sshpass --)
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

echo "==> Running install + check inside the VM..."
"${SSHPASS[@]}" -p admin ssh "${SSH_OPTS[@]}" admin@"$IP" bash <<REMOTE
set -euo pipefail
cd '/Volumes/My Shared Files/dotfiles'
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing upstream Nix inside VM..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
fi
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
./scripts/check.sh ${HOST_NAME}
REMOTE

echo
echo "==> ✅ Pre-flight check passed inside the VM."

if $DO_SWITCH; then
  echo
  echo "==> Running full darwin-rebuild switch inside the VM..."
  "${SSHPASS[@]}" -p admin ssh "${SSH_OPTS[@]}" admin@"$IP" bash <<REMOTE
set -euo pipefail
cd '/Volumes/My Shared Files/dotfiles'
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
echo admin | sudo -S nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#${HOST_NAME}
REMOTE
  echo "==> ✅ Full switch completed inside the VM."
fi

echo
if ! $STOP_AFTER; then
  cat <<EOF
VM '${VM_NAME}' is still running at ${IP}.
  SSH in:           nix run nixpkgs#sshpass -- -p admin ssh ${SSH_OPTS[*]} admin@${IP}
  Stop VM:          tart stop ${VM_NAME}
  Delete VM (~30G): tart delete ${VM_NAME}
EOF
fi
