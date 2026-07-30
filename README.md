# dotfiles

Declarative personal setup for Apple Silicon macOS using nix-darwin,
Home Manager, nix-homebrew, and Homebrew casks. A standalone Linux Home
Manager configuration is also included.

Nix packages and configuration are pinned by `flake.lock`. Homebrew casks
are intentionally used for self-updating GUI applications, so their exact
versions are not pinned. Secrets and private machine data never belong in
this repository.

## Bootstrap a Mac

Create the first macOS account with the short name `gwku`, then run:

```sh
xcode-select --install
git clone https://github.com/gwku/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./install.sh gkmp
```

The installer:

1. installs Determinate Nix when necessary;
2. verifies that the configured macOS account exists;
3. uses the nix-darwin revision pinned by this flake;
4. activates nix-darwin and Home Manager.

After signing into the Mac App Store, restore the declared App Store
applications:

```sh
./scripts/install-mas-apps.sh
```

This installs Amphetamine, HP Smart, Keynote, Microsoft Word, Numbers,
Pages, Todoist, and WireGuard. It is deliberately separate from activation
so a clean VM build never needs Apple ID credentials.

This repository standardises on Determinate Nix. Its official nix-darwin
module prevents nix-darwin from trying to replace the Determinate-managed
daemon and declares the additional Nix settings used by this setup.

## Bootstrap Linux

The Linux target manages the user environment with standalone Home Manager;
it is not a complete NixOS system configuration. On an x86-64 Linux machine,
install Nix if the machine does not already provide it, then run:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
git clone https://github.com/gwku/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
nix run path:.#home-manager -- switch --flake path:.#gwku@workstation
./scripts/smoke-test.sh
```

On NixOS, use the existing system Nix installation and start with the clone.
The same Home Manager target can be imported into a future NixOS system
configuration if system-level NixOS management is added later.

## Daily commands

```sh
# Evaluate every supported platform and build the Mac configuration
./scripts/check.sh gkmp

# Activate
sudo nix run path:.#darwin-rebuild -- switch --flake path:.#gkmp

# Update pinned inputs, then build before switching
nix flake update
./scripts/check.sh gkmp

# Inspect or roll back
darwin-rebuild --list-generations
sudo darwin-rebuild --switch-generation <generation>
```

Fish abbreviations `drs`, `hms`, `nfu`, and `nfc` cover the common
rebuild and update commands.

The Homebrew declaration is exhaustive: activation runs an explicit,
non-zapping `brew bundle cleanup --force`, so formulae and casks removed
from the declaration are also removed from the machine while their user
data is preserved. Close Homebrew-managed applications before switching.

On an existing Mac, first complete a successful switch. Then remove the
privileged leftovers that Homebrew cannot own:

```sh
./scripts/finish-current-mac-cleanup.sh
```

The script moves obsolete Docker launch daemons and privileged helpers to
the Trash, asks macOS to garbage-collect extensions, and tells you if a
reboot is needed. It never deletes the archive directly.

## Testing

Run the non-activating checks first:

```sh
nix flake check path:. --all-systems --no-build
nix build path:.#darwinConfigurations.gkmp.system
```

For a clean-machine test on Apple Silicon:

```sh
./scripts/test-vm.sh --switch --stop-after
```

The VM test installs Determinate Nix, builds the full configuration,
performs a real switch, and runs the runtime smoke tests. It is still
important to test a fresh VM rather than relying only on a previously
mutated `dotfiles-test` VM.

After activation, run:

```sh
./scripts/smoke-test.sh
```

## SSH without secrets in Git

Bitwarden is the source of truth for private SSH keys and private host
metadata. Home Manager:

- points OpenSSH at the Bitwarden desktop SSH-agent socket;
- installs `bw-ssh-sync`;
- includes the generated `~/.ssh/config.bitwarden`;
- synchronizes metadata during activation, prompting to unlock the CLI when
  it is logged in but locked.

Private keys are never written by Nix or `bw-ssh-sync`. The sync command
writes only public-key selector files under `~/.ssh/bitwarden/` and Host
blocks generated from Bitwarden custom fields.

### First setup on a Mac

1. Open the Bitwarden desktop application, sign in, enable its SSH agent,
   and allow Bitwarden to remain open in the background.
2. Log the CLI into the same account once with `bw login`.
3. Run `bw-ssh-sync`. If the CLI vault is locked, it prompts to unlock it
   for that command.
4. Verify the agent and a configured host:

```sh
ssh-add -L
ssh -G github.com
```

Every native Bitwarden SSH item is offered by the desktop agent
automatically; there is no hardcoded key list in this repository. Host
aliases require metadata because a key alone cannot reveal its hostname,
username, or port.

### Bitwarden SSH item metadata

Add a Text custom field named `ssh_config` to any SSH item that needs one
or more host aliases. Use `{{identity_file}}` where the generated public
selector belongs:

```sshconfig
Host example
  HostName example.internal
  User deploy
  Port 22
  IdentityFile {{identity_file}}
  IdentitiesOnly yes
```

Run `bw-ssh-sync` after adding or changing an item. The command discovers
all SSH items dynamically, validates each public-key fingerprint,
regenerates the config atomically, and removes stale generated selector
files. Custom fields such as `source_path`, `public_key_comment`, and
`host_aliases` are retained as provenance but are not required at
runtime.

Activation prompts for `bw unlock` when the CLI is logged in but locked. On
a clean Mac where `bw login` has never run, it preserves the last generated
configuration and skips with setup instructions. Use
`bw-ssh-sync --non-interactive` only for automation that must never prompt.
The repository contains neither secret blobs nor vault credentials.

## State restored outside Nix

Nix does not reproduce credentials, application databases, or cloud
accounts. The post-bootstrap checklist is maintained in
[`UNMANAGED.md`](UNMANAGED.md). Important examples include:

- enabling Bitwarden's desktop SSH agent and running `bw-ssh-sync`;
- AWS, Kubernetes, GitHub CLI, GPG, and Stripe authentication;
- Android SDK platforms, system images, and accepted licences;
- application sign-ins and synced IDE/editor settings;
- iCloud, Wi-Fi, Bluetooth, displays, and Time Machine.

Public Cursor extensions, Shopify CLI 4.5.2, and Google Lighthouse 13.4.1
are pinned by the flake. Cursor's bundled `anysphere.*` extensions continue
to ship with Cursor itself.

Home Manager uses the backup suffix `.hm-backup` when taking over an
existing file. Inspect those backups after the first successful switch
and remove them only after confirming the managed replacement works.

## Hosts

- `gkmp` — Apple Silicon MacBook
- `workstation` — x86-64 Linux placeholder
