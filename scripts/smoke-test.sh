#!/usr/bin/env bash
# Runtime checks to run after a successful Home Manager activation.

set -euo pipefail

fail() {
  echo "smoke test failed: $*" >&2
  exit 1
}

for command in fish nvim wezterm git ssh bw-ssh-sync tofu go cloudflared psql shopify lighthouse fzf zoxide infisical stripe; do
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

btop_config="$HOME/.config/btop/btop.conf"
test -L "$btop_config" ||
  fail "btop configuration is not managed by Home Manager"
grep -qx 'cpu_bottom = True' "$btop_config" ||
  fail "btop layout preference was not restored"

expected_agent="$HOME/.bitwarden-ssh-agent.sock"
configured_agent="$(
  ssh -G github.com 2>/dev/null |
    awk '$1 == "identityagent" { print $2; exit }'
)"
test "$configured_agent" = "$expected_agent" ||
  fail "OpenSSH is not configured for the Bitwarden agent"

case "$(uname -s)" in
  Darwin)
    command -v mas >/dev/null 2>&1 || fail "missing command: mas"
    command -v blueutil >/dev/null 2>&1 || fail "missing command: blueutil"

    test "$(
      env -u __HM_SESS_VARS_SOURCED \
        fish -lc "printf %s \"\$HOMEBREW_NO_ANALYTICS\""
    )" = 1 ||
      fail "Homebrew analytics opt-out is not configured"
    HOMEBREW_NO_ANALYTICS=1 /opt/homebrew/bin/brew analytics state |
      grep -q 'InfluxDB analytics are disabled' ||
      fail "Homebrew does not report analytics as disabled"

    test -e "/Applications/Nix Apps/WezTerm.app" ||
      fail "nix-darwin WezTerm application bundle is missing"

    cursor_user_dir="$HOME/Library/Application Support/Cursor/User"
    test -L "$cursor_user_dir/settings.json" ||
      fail "Cursor settings are not managed by Home Manager"
    test -L "$cursor_user_dir/keybindings.json" ||
      fail "Cursor keybindings are not managed by Home Manager"
    jq -e '
      .["git.autofetch"] == true
      and .["workbench.colorTheme"] == "Cursor Light"
      and (has("remote.SSH.remotePlatform") | not)
    ' "$cursor_user_dir/settings.json" >/dev/null ||
      fail "Cursor portable settings were not restored safely"

    test "$(defaults read com.mowglii.ItsycalApp ShowEventDays)" = 7 ||
      fail "Itsycal preferences were not restored"
    test "$(defaults read com.jordanbaird.Ice AutoRehide)" = 1 ||
      fail "Ice preferences were not restored"
    test "$(defaults read com.pilotmoon.scroll-reverser HideIcon)" = 1 ||
      fail "Scroll Reverser preferences were not restored"
    test "$(defaults read org.p0deje.Maccy historySize)" = 999 ||
      fail "Maccy preferences were not restored"

    test "$(
      defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID
    )" = "com.apple.keylayout.USInternational-PC" ||
      fail "USInternational-PC is not the selected keyboard layout"
    test "$(
      defaults read NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically
    )" = 1 ||
      fail "automatic light/dark appearance is not enabled"
    defaults read NSGlobalDomain NSUserDictionaryReplacementItems |
      grep -q 'replace = omw' ||
      fail "text replacements were not restored"
    test "$(
      defaults read com.apple.assistant.support "Dictation Enabled"
    )" = 1 ||
      fail "Dictation is not enabled"
    test "$(
      defaults read com.apple.assistant.support "Assistant Enabled"
    )" = 0 ||
      fail "Siri/Assistant is not disabled"

    battery_display_sleep="$(
      pmset -g custom |
        awk '
          /Battery Power:/ { power = "battery" }
          /AC Power:/ { power = "ac" }
          power == "battery" && $1 == "displaysleep" { print $2; exit }
        '
    )"
    ac_display_sleep="$(
      pmset -g custom |
        awk '
          /Battery Power:/ { power = "battery" }
          /AC Power:/ { power = "ac" }
          power == "ac" && $1 == "displaysleep" { print $2; exit }
        '
    )"
    test "$battery_display_sleep" = 2 ||
      fail "battery display sleep is not set to two minutes"
    test "$ac_display_sleep" = 10 ||
      fail "AC display sleep is not set to ten minutes"

    test "$(blueutil --power)" = 1 ||
      fail "Bluetooth power policy was not applied"

    for login_agent in \
      elgato-wave-link \
      ice \
      itsycal \
      maccy \
      nextcloud \
      scroll-reverser; do
      test -f "$HOME/Library/LaunchAgents/org.nix-community.home.${login_agent}.plist" ||
        fail "missing managed login agent: $login_agent"
    done

    if grep -Ev '^[[:space:]]*(#|$)' /etc/pam.d/sudo_local 2>/dev/null |
      grep -q 'pam_tid.so'; then
      fail "biometric authentication for sudo is still enabled"
    fi

    fdesetup status | grep -q '^FileVault is On' ||
      fail "FileVault is not enabled"

    configured_shell="$(/usr/bin/dscl . -read "/Users/$USER" UserShell | /usr/bin/awk '{ print $2 }')"
    case "$configured_shell" in
      /nix/store/*/bin/fish) ;;
      *) fail "login shell is not the nix-managed Fish: $configured_shell" ;;
    esac
    ;;
  Linux)
    ;;
  *)
    fail "unsupported operating system: $(uname -s)"
    ;;
esac

echo "All runtime smoke tests passed."
