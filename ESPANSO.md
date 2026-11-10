# Text expansion: Espanso

Espanso runs on macOS, Windows, and Linux.
The public repository contains only generic first-run defaults in
`modules/home/espanso/files/`. Setup copies missing defaults into a private
runtime outside the checkout. Edit that private runtime with your text editor;
edits never write back to public Git. Espanso reloads changes
automatically.

## Current setup and normal use

On macOS the engine comes from the declared Homebrew cask. Home Manager
links the private configuration, installs the pinned emoji package, and
registers Espanso's official login service. Open Espanso from Applications
to complete its first-run setup.
The activation explicitly enables the login agent, including when launchd has
retained a disabled state from a previous installation.
When applying from SSH without a graphical user session, startup registration
is deferred. Open Espanso once after graphical login to complete that step.

Grant **Espanso** Accessibility permission in System Settings → Privacy &
Security → Accessibility. Approve Input Monitoring only if macOS requests it.
Restart Espanso after approval. These permissions require a person at the Mac;
configuration files cannot grant them.

- Type a trigger to insert its expansion immediately; no trailing space is needed.
- **Alt/Option + Shift + Space** opens the searchable snippet picker.
- An immediate Backspace undoes an expansion where supported.
- Pause or resume expansion from Espanso's menu-bar/tray icon.
- Run `espanso edit` or open a private YAML file in your text editor to edit
  snippets and configuration.
- Clipboard helpers read the current clipboard only when their trigger runs.
  Long expansions use clipboard insertion. Clipboard-history apps such as
  Maccy may retain inserted text even after Espanso restores the clipboard.

## Emoji package

The [all-emojis](https://hub.espanso.org/all-emojis/) package is pinned to
**0.1.0**, with its archive SHA-256 in
`packages/espanso-all-emojis/default.nix`. Home Manager fetches and verifies
it during the build, then setup copies it into the private runtime on first
installation. Existing installations and local package edits are preserved.

Type `:smile:` for 😄, or search the built-in snippet picker for an emoji.
This package uses spaces in multiword names, for example `:neutral face:`.
Check installation with `espanso package list`.

For a manual setup without Nix (including Windows), install the same version:

```sh
espanso package install all-emojis --version 0.1.0
```

## Starter expansions

Dates and Markdown helpers use Espanso's built-in features. UUID generation
uses Python's standard library; `python` must be on Espanso's PATH. The Nix
setup already installs it; install Python on Windows before using this helper.
No external service or AI API is used.

| Triggers | Expansion |
| --- | --- |
| `;date`, `;dnl` | Today's date as YYYY-MM-DD or DD-MM-YYYY |
| `;time`, `;stamp` | Time, or timestamp including UTC offset |
| `;unix` | Current Unix timestamp in seconds |
| `;mdlink` | Markdown link using the clipboard as its URL; cursor inside the label |
| `;mdcode`, `;mdclip` | Empty fenced code block, or clipboard inside a code block |
| `;todo` | Markdown checkbox |
| `;guid`, `;uuid` | Generate a fresh random UUID v4 on every expansion |

There are no AI prompts, canned replies, fill-in reply forms, or writing
templates. Cursor markers work best in normal text fields. Clipboard Markdown helpers do not escape
arbitrary Markdown; use them with a URL or text that fits the chosen delimiter.

## Personal snippets

On macOS and Linux the active directory is
`~/.config/espanso-private/runtime/` (or under `$XDG_CONFIG_HOME` on Linux).
`match/personal.yml` links to `~/.config/espanso-private/personal.yml`;
both paths are outside the public checkout. The private directory is mode
0700 and personal files are mode 0600. New files are protected by the private
parent directory even if your editor chooses a more permissive file mode.
The managed personal-file link is relative, so it also works when the private
directory is restored under a different home path. Setup repairs older broken
absolute links without copying personal values into the repository.

Personal shortcuts include `;name`, `;email`, `;cmail`, numbered `;mNN`
email shortcuts, `;addr`, `;street`, `;postcode`, `;city`, and Digitura's
`;phone`, `;kvk`, `;btw`, and `;bank`. The email
picker shows actual addresses locally. The private mapping is recorded
in `~/.config/espanso-private/shortcuts.txt`, outside the repository. Signature
templates have been removed. Keep a private backup of this directory; public
Git cannot restore personal values.

Git ignores `*.local.yml` and `*.local.yaml` anywhere under the Espanso
configuration, old editor backup folders, and installed package files.
These ignore rules are a fallback for old setups, not the privacy mechanism.
Do not add personal files or personal symlinks anywhere in the checkout.
All active files and backups stay in the private runtime.
Git ignores are not a secrecy boundary:
Nix can copy ordinary ignored files into its readable store during a build.
Passwords, API keys, and recovery codes belong in Bitwarden, not snippets.

## macOS and Linux with Nix

Apply the dotfiles normally. Generic defaults are read from the standard checkout
at `~/development/dotfiles`; edit the module if that checkout moves.
`espanso-setup` creates missing default files without overwriting private edits,
then connects Espanso's standard configuration path to the private runtime.
It refuses a runtime inside the public checkout. Existing configurations are
renamed to a timestamped sibling backup before the link is installed. Backups
are preserved, not imported automatically: copy their required matches into private YAML
if they contain expansions you need.

On Linux, Home Manager installs the engine and emoji package and starts
Espanso with the graphical session. It selects X11 or Wayland at runtime.
Wayland needs machine-level input permissions; Home Manager alone cannot
grant these. On NixOS enable `services.espanso` with `pkgs.espanso-wayland` in
the system configuration and disable the Home Manager service to avoid two
instances. On other distributions follow the upstream
[Wayland installation instructions](https://espanso.org/docs/install/linux/#wayland).
Verify expansion in the actual compositor and keyboard layout before relying
on it. No Linux machine was activated as part of the Mac setup.

For a manual Mac setup without a full activation:

```sh
brew install --cask espanso
python3 scripts/setup-espanso.py
espanso package install all-emojis --version 0.1.0
espanso service register
espanso service start
```

The setup script preserves any displaced configuration and refuses unsafe
source/destination nesting. Stop Espanso before changing its directory link.

## Restore personal shortcuts on another device

Pushing and applying public dotfiles installs the engine, emoji package, and generic
helpers. It does **not** transfer email addresses, postal details, business
identifiers, or bank details. There is no automatic private synchronization.

Transfer only `~/.config/espanso-private/personal.yml` using an authenticated
private channel or a private backup. Keep it outside every public checkout.
On another Mac or Linux desktop, after applying these dotfiles, restore it as
follows (replace the example backup path with the actual private file):

```sh
install -d -m 700 ~/.config/espanso-private
install -m 600 /path/to/private-backup/personal.yml ~/.config/espanso-private/personal.yml
espanso-setup
espanso service restart
```

If `$XDG_CONFIG_HOME` is customized on Linux, use its `espanso-private`
directory instead. On Windows restore `personal.yml` directly under
`%APPDATA%\espanso-private`, then rerun the Python setup command below.
There is no need to copy machine-specific links, migration backups, cached
files, or the source-discovery metadata. Additional snippets in the private
`runtime/match/` directory need their own private transfer. The emoji package
comes from the pinned public package, so it does not need a private transfer.

Each Mac needs its own Accessibility approval. Test `;date`, `;guid`, `;cmail`,
and `;addr` in a scratch document after restoring. Existing local matches on
the destination are preserved in the timestamped backup when setup replaces
an old configuration directory; import any of those you still need.

## Windows

These dotfiles do not manage Windows applications with Nix. Install Espanso
using its [Windows installer](https://espanso.org/docs/install/win/).

Clone this repository and stop Espanso. With Python installed and
Windows Developer Mode enabled (to permit directory symlinks), run:

```powershell
python scripts/setup-espanso.py
espanso package install all-emojis --version 0.1.0
```

The script seeds `%APPDATA%\espanso-private\runtime` and links
`%APPDATA%\espanso` to it. Alternatively create that private runtime and a
directory junction with PowerShell after moving any existing Espanso
configuration to a backup. Restart Espanso. All shared
expansions are portable; restore personal files from private backup.
Windows was not activated or tested here.

## Verification

```sh
espanso path
espanso match list --only-triggers
espanso service check
espanso service status
git diff --check
```

Finally type `;date` and test a clipboard helper in a scratch
document. Listing matches validates loading, but does not prove that macOS
has granted Accessibility or that insertion works in every application.
