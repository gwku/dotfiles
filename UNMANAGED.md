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

## Post-bootstrap manual steps

After the first `darwin-rebuild switch`:

1. Drop SSH keys into `~/.ssh/` (chmod 600). Never committed.
2. Populate `~/.config/fish/conf.d/secrets.fish` with any per-session env vars.
3. Sign into apps with persistent auth (1Password / Bitwarden, Slack, JetBrains, etc.).
4. JetBrains Toolbox: open the app and reinstall the IDEs you use.

## Login items / system services

These can't be declared yet without extra modules; configure via each app's preferences.

- **OrbStack** — start on login.
- **Ice / Itsycal / Maccy** — start on login.
- **Bitwarden** — system auth integration / browser extension hooks.
