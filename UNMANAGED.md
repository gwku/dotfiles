# Unmanaged macOS apps

Things you have installed that aren't declared by Nix or Homebrew in this repo. Everything self-updating now lives in either [`modules/darwin/homebrew.nix`](modules/darwin/homebrew.nix) (casks) or one of the [`modules/home/dev/`](modules/home/dev) modules (Nix packages).

## Manually installed apps (vendor installers / Mac App Store)

| App | Source | Why manual |
|---|---|---|
| JetBrains Toolbox | jetbrains.com | Toolbox manages its own IDE installs in `~/Applications`. Don't fight it. |
| IntelliJ IDEA, PyCharm, Rider, WebStorm | via Toolbox | See above. |
| Android Studio | via Toolbox or direct | See above. |
| LM Studio | lmstudio.ai | Vendor installer; not in nixpkgs/casks. |
| Amphetamine | Mac App Store | MAS-only. |
| Cog | Mac App Store | Audio player. |
| Cotypist | direct / MAS | |
| FileZilla | filezilla-project.org | |
| HP (printer) | hp.com | Driver bundle. |
| Kobo | kobo.com | E-reader sync. |
| Microsoft Word | MAS / Microsoft 365 | |
| Numbers / Pages / Keynote / GarageBand | Apple (built-in) | |
| OpenMTP | github.com/ganeshrvel/openmtp | Android file transfer. |
| Safari | Apple (built-in) | |
| T3 Code (Alpha) | direct | AI IDE alpha. |
| Todoist | Mac App Store | |
| Tolaria | direct | MTG library. |
| WireGuard | Mac App Store | App-store WireGuard client (the CLI `wireguard-tools` is in Nix). |
| Zen | zen-browser.app | |
| kdenlive | direct | Video editor. |

## Login items

nix-darwin has no first-class API for "open at login" GUI items, so these have to be toggled in each app's preferences. The current set on this machine:

- Ice
- Maccy
- Cotypist
- Itsycal
- Scroll Reverser
- Nextcloud

Add OrbStack to this list if you want it to auto-start (currently it doesn't).

## macOS settings nix-darwin can't manage

| Setting | Current value | How to set |
|---|---|---|
| Keyboard input source | USInternational-PC | System Settings → Keyboard → Input Sources |
| Automatic dark/light switching | Enabled | System Settings → Appearance → Auto (don't set `AppleInterfaceStyle` in nix-darwin or you'll lock it) |
| Smart quotes style | `"..."` / `'...'` curly | System Settings → Keyboard → Text Replacements |
| Adobe / Google / JetBrains LaunchAgents | Self-installed by each app | App preferences |

## Post-bootstrap manual steps

After the first `darwin-rebuild switch`:

1. Drop SSH keys into `~/.ssh/` (chmod 600). Never committed.
2. Populate `~/.config/fish/conf.d/secrets.fish` with any per-session env vars.
3. Sign into apps with persistent auth (Bitwarden, Slack, JetBrains, etc.).
4. JetBrains Toolbox: open the app and reinstall the IDEs you use.
5. Re-confirm input source = USInternational-PC and "Auto" appearance.
6. Toggle login items in each app's preferences if they don't auto-add themselves.
