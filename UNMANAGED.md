# macOS state outside Nix

This file records the manual part of a clean Mac setup. Self-updating
casks live in [`modules/darwin/homebrew.nix`](modules/darwin/homebrew.nix);
Nix packages live under [`modules/home/`](modules/home/).

## Manually installed applications

| Application | Restore method |
|---|---|
| JetBrains Toolbox | Vendor installer; use Toolbox to restore IDEs |
| IntelliJ IDEA, PyCharm, Rider, WebStorm | JetBrains Toolbox |
| Android Studio | JetBrains Toolbox or vendor installer |
| LM Studio | Vendor installer |
| Little Snitch | Vendor installer and manual rules restore |
| Cog | Vendor installer |
| Cotypist, FileZilla, HP printer tools, Kobo, OpenMTP | Vendor installers |
| RapidRAW, T3 Code, Tolaria, Zen, kdenlive | Vendor/project installers |

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
|---|---|
| Keyboard input source | USInternational-PC |
| Appearance | Automatic light/dark switching |
| Text replacements and smart quotes | Restore in Keyboard settings |
| Dictation and Siri | Dictation on; Siri/Assistant off |
| iCloud | Sign in manually |
| Displays and Spaces | Reconfigure for attached displays |
| Power management | Battery display sleep 2 min; AC display sleep 10 min; review with `pmset -g custom` |
| Time Machine, Wi-Fi, Bluetooth | Restore or configure per machine |
| Little Snitch rules | Restore through Little Snitch |
| OBS Virtual Camera | Approve the camera system extension in Login Items & Extensions |

Symbolic keyboard shortcuts and the screen-recording cursor/click
preferences are managed by nix-darwin. Menu-bar item positioning remains
machine-local because macOS rewrites those positions and Ice manages the
visible layout.

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

1. Sign into the Bitwarden desktop app, enable its SSH agent, run
   `bw login`, then run `bw-ssh-sync`. Confirm `ssh-add -L` lists the
   expected keys and test at least one host alias. Private keys and host
   metadata are restored from native Bitwarden SSH items; do not restore
   `~/.ssh/config.local`.
2. Populate `~/.config/fish/conf.d/local.fish` for non-secret local paths
   and `secrets.fish` for environment secrets.
3. Restore or re-authenticate AWS, Kubernetes, GitHub CLI, GPG, Stripe,
   Bitwarden, and other cloud tools.
4. Run `rustup default stable`.
5. Restore Android SDK components. The previous machine used Android
   platforms 33–36, build-tools 30.0.3 and 33–36.1, the emulator,
   sources for Android 36, and an Android 36.1 system image.
6. Install JetBrains Toolbox and restore the required IDEs.
7. Sign into the Mac App Store and run `./scripts/install-mas-apps.sh`.
8. Sign into GUI applications and enable settings sync where available.
9. Confirm the keyboard source, automatic appearance, login items,
   display layout, and power settings.
10. Approve OBS Virtual Camera if it is needed.
11. Run `./scripts/smoke-test.sh`.
12. On a migrated Mac, run `./scripts/finish-current-mac-cleanup.sh`
    and reboot if it reports a pending system-extension uninstall.

When adding a Bitwarden SSH item, add an `ssh_config` Text custom field if
it needs a Host alias, then rerun `bw-ssh-sync`. Use
`{{identity_file}}` for its generated public selector. Items without that
field are still exposed by the agent but do not create Host blocks.

Do not place credentials, private keys, tokens, private SSH host data, or
encrypted secret blobs in this repository.
