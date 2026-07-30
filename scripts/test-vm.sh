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
#   VM_DISK_SIZE   Disk size in GB (default: 140; the full cask set needs it).

set -euo pipefail

IMAGE="${TART_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
VM_NAME="${VM_NAME:-dotfiles-test}"
HOST_NAME="${HOST_NAME:-gkmp}"
VM_DISK_SIZE="${VM_DISK_SIZE:-140}"
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
if ! tart list --format json 2>/dev/null |
  grep -E "\"Name\"[[:space:]]*:[[:space:]]*\"${VM_NAME}\"" >/dev/null; then
  echo "==> Cloning ${IMAGE} into local VM '${VM_NAME}' (one-time, ~30-40 GB)..."
  tart clone "$IMAGE" "$VM_NAME"
fi

# The full Nix closure plus large casks (notably MacTeX) does not fit in
# the base image's 50 GB disk. The Cirrus base image's Tart guest agent
# expands the macOS APFS container on the next boot.
tart set "$VM_NAME" --disk-size "$VM_DISK_SIZE"

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

# Kill any stale `tart run` for this VM left over from a previous
# invocation that didn't clean up — otherwise we hit Apple's
# "number of VMs exceeds the system limit" cap on the next start.
if pgrep -f "tart run ${VM_NAME}" >/dev/null 2>&1; then
  echo "==> Killing stale 'tart run ${VM_NAME}' processes..."
  pkill -f "tart run ${VM_NAME}" || true
  sleep 2
fi
# Also ensure tart's view of state is 'stopped'.
tart stop "$VM_NAME" 2>/dev/null || true

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

# Use password-only authentication so keys loaded on the host cannot
# exhaust the guest's authentication attempts.
SSHPASS=(nix --extra-experimental-features 'nix-command flakes' run nixpkgs#sshpass --)
SSH_OPTS=(
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o PubkeyAuthentication=no
  -o PreferredAuthentications=password
)

# An open TCP port can precede sshd being ready for key exchange after
# boot. Wait for an authenticated command instead of only probing port 22.
echo "==> Waiting for VM SSH login to be ready (up to 5 min)..."
IP=""
SSH_READY=false
SSH_STABLE_COUNT=0
for _ in $(seq 1 60); do
  IP="$(tart ip "$VM_NAME" 2>/dev/null || true)"
  if [[ -n "$IP" ]] &&
    nc -z "$IP" 22 2>/dev/null &&
    "${SSHPASS[@]}" -p admin ssh "${SSH_OPTS[@]}" \
      admin@"$IP" true >/dev/null 2>&1; then
    SSH_STABLE_COUNT=$((SSH_STABLE_COUNT + 1))
    if [[ "$SSH_STABLE_COUNT" -ge 3 ]]; then
      SSH_READY=true
      break
    fi
  else
    SSH_STABLE_COUNT=0
  fi
  sleep 5
done
if ! $SSH_READY; then
  echo "VM did not become SSH-reachable in 5 minutes." >&2
  echo "Check the log: tail -30 ${LOG_FILE}" >&2
  exit 1
fi
echo "    VM up at ${IP}"

echo "==> Running install + check inside the VM..."
"${SSHPASS[@]}" -p admin ssh "${SSH_OPTS[@]}" admin@"$IP" \
  bash -s -- "$HOST_NAME" <<'REMOTE'
set -euo pipefail
HOST_NAME="$1"
cd '/Volumes/My Shared Files/dotfiles'

# Try to source an existing Nix profile first so an already-installed
# Nix doesn't get re-installed. Non-interactive bash doesn't read
# /etc/bashrc, so we have to find nix-daemon.sh ourselves.
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Determinate Nix inside VM..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  sleep 3
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! nix --extra-experimental-features 'nix-command flakes' \
  store ping --store daemon >/dev/null 2>&1; then
  echo "Starting the Nix daemon..."
  echo admin | sudo -S launchctl kickstart -k \
    system/systems.determinate.nix-daemon 2>/dev/null ||
    echo admin | sudo -S launchctl kickstart -k \
      system/org.nixos.nix-daemon 2>/dev/null ||
    echo admin | sudo -S launchctl load -w \
      /Library/LaunchDaemons/org.nixos.nix-daemon.plist
  for _ in $(seq 1 10); do
    nix --extra-experimental-features 'nix-command flakes' \
      store ping --store daemon >/dev/null 2>&1 && break
    sleep 1
  done
  nix --extra-experimental-features 'nix-command flakes' \
    store ping --store daemon >/dev/null
fi

export NIX_REMOTE=daemon
./scripts/check.sh "$HOST_NAME"
REMOTE

echo
echo "==> ✅ Pre-flight check passed inside the VM."

if $DO_SWITCH; then
  echo
  echo "==> Running full darwin-rebuild switch inside the VM..."
  "${SSHPASS[@]}" -p admin ssh "${SSH_OPTS[@]}" admin@"$IP" \
    bash -s -- "$HOST_NAME" <<'REMOTE'
set -euo pipefail
HOST_NAME="$1"
cd '/Volumes/My Shared Files/dotfiles'
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
export NIX_REMOTE=daemon

# The flake hardcodes username = "gwku". nix-darwin's
# system.primaryUser must point at an existing local user, so create
# it inside the VM if it's not there.
PRIMARY_USER="$(grep -oE 'name *= *"[^"]+";' flake.nix | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
if ! id "$PRIMARY_USER" >/dev/null 2>&1; then
  echo "Creating local user '$PRIMARY_USER' for nix-darwin activation..."
  echo admin | sudo -S sysadminctl -addUser "$PRIMARY_USER" \
    -fullName "$PRIMARY_USER" \
    -home "/Users/$PRIMARY_USER" \
    -shell /bin/bash 2>&1 | tail -5
  # sysadminctl assigns but doesn't physically create the home dir.
  echo admin | sudo -S createhomedir -c -u "$PRIMARY_USER" 2>&1 | tail -3
fi

# A real primary Mac user is an administrator and enters their password
# before darwin-rebuild. This synthetic account has no usable password,
# so grant VM-only non-interactive sudo for Homebrew cask installers.
echo admin | sudo -S dseditgroup -o edit -a "$PRIMARY_USER" -t user admin
echo admin | sudo -S /bin/sh -c \
  "printf '%s\n' '$PRIMARY_USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/dotfiles-test"
echo admin | sudo -S chmod 0440 /etc/sudoers.d/dotfiles-test

# The cirruslabs base image ships /opt/homebrew owned by admin.
# nix-homebrew needs that prefix owned by the primary user; chown it.
if [ -d /opt/homebrew ] && [ "$(stat -f %Su /opt/homebrew)" != "$PRIMARY_USER" ]; then
  echo "Transferring /opt/homebrew ownership to $PRIMARY_USER..."
  echo admin | sudo -S chown -R "$PRIMARY_USER:staff" /opt/homebrew
fi

# The Nix installer modifies /etc/bashrc and /etc/zshrc; nix-darwin
# wants to manage those files and refuses to overwrite. Rename them.
echo admin | sudo -S bash -c '
  for f in /etc/bashrc /etc/zshrc; do
    if [ -f "$f" ] && [ ! -f "$f.before-nix-darwin" ]; then
      mv "$f" "$f.before-nix-darwin"
    fi
  done
'

# nix's git+file:// default fetcher uses libgit2, which refuses to
# open a repo it doesn't own. The shared-folder mount is owned by
# 'admin'; sudo runs nix as root. Use the path: URL scheme to bypass
# libgit2 entirely.
FLAKE_PATH="path:/Volumes/My%20Shared%20Files/dotfiles"

echo admin | sudo -SE env PATH="$PATH" NIX_REMOTE=daemon \
  nix --extra-experimental-features 'nix-command flakes' \
  run "${FLAKE_PATH}#darwin-rebuild" -- switch --flake "${FLAKE_PATH}#${HOST_NAME}"

echo "Running post-switch smoke tests as $PRIMARY_USER..."
echo admin | sudo -S -H -u "$PRIMARY_USER" env \
  HOME="/Users/$PRIMARY_USER" \
  PATH="/etc/profiles/per-user/$PRIMARY_USER/bin:/run/current-system/sw/bin:/usr/bin:/bin" \
  /bin/bash -c "cd '/Volumes/My Shared Files/dotfiles' && ./scripts/smoke-test.sh"
REMOTE
  echo "==> ✅ Full switch and runtime smoke tests completed inside the VM."
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
