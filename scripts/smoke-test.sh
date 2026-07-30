#!/usr/bin/env bash
# Runtime checks to run after a successful nix-darwin switch.

set -euo pipefail

fail() {
  echo "smoke test failed: $*" >&2
  exit 1
}

for command in fish nvim wezterm git ssh bw-ssh-sync tofu go cloudflared psql mas shopify lighthouse; do
  command -v "$command" >/dev/null 2>&1 || fail "missing command: $command"
done

fish -n "$HOME/.config/fish/config.fish"
fish -i -c 'type -q z' ||
  fail "zoxide Fish integration did not provide the z command"

# Neovim normally exits successfully even when init.lua printed an error.
# Convert any startup error recorded in v:errmsg into a failing exit code.
if ! nvim --headless \
  '+if v:errmsg != "" | cquit | endif' \
  '+quitall' >/tmp/dotfiles-nvim-smoke.log 2>&1; then
  cat /tmp/dotfiles-nvim-smoke.log >&2
  fail "Neovim configuration did not start cleanly"
fi

wezterm --config-file "$HOME/.config/wezterm/wezterm.lua" \
  show-keys >/dev/null

ssh -G github.com >/dev/null 2>&1 ||
  fail "SSH configuration could not resolve github.com"

expected_agent="$HOME/.bitwarden-ssh-agent.sock"
configured_agent="$(
  ssh -G github.com 2>/dev/null |
    awk '$1 == "identityagent" { print $2; exit }'
)"
test "$configured_agent" = "$expected_agent" ||
  fail "OpenSSH is not configured for the Bitwarden agent"

test -e "/Applications/Nix Apps/WezTerm.app" ||
  fail "nix-darwin WezTerm application bundle is missing"

configured_shell="$(/usr/bin/dscl . -read "/Users/$USER" UserShell | /usr/bin/awk '{ print $2 }')"
case "$configured_shell" in
  /nix/store/*/bin/fish) ;;
  *) fail "login shell is not the nix-managed Fish: $configured_shell" ;;
esac

echo "All runtime smoke tests passed."
