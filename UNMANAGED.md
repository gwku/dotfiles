# macOS state outside Nix

This file records the manual part of a clean Mac setup. Self-updating
casks live in [`modules/darwin/homebrew.nix`](modules/darwin/homebrew.nix);
Nix packages live under [`modules/home/`](modules/home/).

## Manually installed applications

| Application | Restore method |
| --- | --- |
| Little Snitch | Vendor installer and manual rules restore |
| Cotypist, HP printer drivers, Kobo | Vendor installers |

Android Studio and Rider are Homebrew casks. Their settings, plugins,
licences, and account state remain external. RapidRAW is installed through
Nix; Cog, Cyberduck, LM Studio, OpenMTP, and Zen are Homebrew casks.

## Mac App Store applications

Sign into the App Store, then run:

```sh
./scripts/install-mas-apps.sh
```

The idempotent script installs Amphetamine, HP Smart, Keynote, Microsoft
Word, Numbers, Pages, Todoist, and WireGuard by their numeric App Store
IDs. Apple ID credentials remain outside the repository.

## Login items

Confirm these after installing their applications:

- Elgato Wave Link
- Ice
- Maccy
- Cotypist
- Itsycal
- Scroll Reverser
- Nextcloud

OrbStack is not currently configured to open at login.

## Settings requiring manual work

| Setting/state | Current intent |
| --- | --- |
| Keyboard input source | USInternational-PC |
| Appearance | Automatic light/dark switching |
| Text replacements and smart quotes | Restore in Keyboard settings |
| Dictation and Siri | Dictation on; Siri/Assistant off |
| iCloud | Sign in manually |
| Displays and Spaces | Reconfigure for attached displays |
| Power | Display sleep: battery 2 min; AC 10 min |
| Time Machine, Wi-Fi, Bluetooth | Restore or configure per machine |
| Little Snitch rules | Restore through Little Snitch |
| OBS camera | Approve extension in Login Items & Extensions |

Symbolic keyboard shortcuts and the screen-recording cursor/click
preferences are managed by nix-darwin. Menu-bar item positioning remains
machine-local because macOS rewrites those positions and Ice manages the
visible layout.

## Application configuration coverage

Home Manager owns the portable Cursor settings, keybindings, and public
extension set. Private `remote.SSH.remotePlatform` mappings are intentionally
excluded: SSH aliases come from Bitwarden metadata, and Cursor can detect the
remote platform when it connects. Home Manager also owns the current `btop`
layout preference.

nix-darwin restores the portable preferences for Itsycal, Ice, Maccy, and
Scroll Reverser. Window positions, menu-bar item positions, update timestamps,
calendar identifiers, and migration/runtime markers remain machine-local.
Easy Move+Resize currently has no user preference domain to restore.

OBS scenes and profiles remain external because the current collection embeds
hardware-specific audio device identifiers. Browser, Thunderbird, messaging,
Bitwarden, Nextcloud, LM Studio, and JetBrains/Android Studio profiles also
remain external because they contain account state, credentials, databases,
large assets, licences, or machine-specific data. Restore them through the
application's own sync/login flow or a private backup, never through this
repository.

## Project-local commands

These are intentionally rebuilt from their project repositories rather
than copied into this repository:

- `terraform-provider-staticform`: from
  `~/development/terraform-provider-staticform` using its Go build/install
  instructions;
- `search-resoftware-customers`: symlinked from
  `~/development/resoftware-customers` after that private project is
  restored.

Shopify CLI and Google Lighthouse are Nix packages in this repository.
Cursor's public extension set is pinned through Home Manager. Cursor's
bundled `anysphere.*` extensions are supplied by Cursor itself.

## Post-bootstrap checklist

The complete, ordered first-machine runbook is
[`POST-INSTALL.md`](POST-INSTALL.md). It is the single source of truth for
account sign-ins, SSH restoration, privacy permissions, developer
authentication, SDKs, application data, machine-local settings, and final
verification. The sections above document why those steps remain outside
Nix.

When adding a Bitwarden SSH item, add an `ssh_config` Text custom field if
it needs a Host alias, then rerun `bw-ssh-sync`. Use
`{{identity_file}}` for its generated public selector. Items without that
field are still exposed by the agent but do not create Host blocks.

Do not place credentials, private keys, tokens, private SSH host data, or
encrypted secret blobs in this repository.
