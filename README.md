# dotfiles

Declarative personal setup for Apple Silicon macOS using nix-darwin,
Home Manager, nix-homebrew, and Homebrew casks. A standalone Linux Home
Manager configuration is also included.

Nix packages and configuration are pinned by `flake.lock`. Homebrew casks
are intentionally used for self-updating GUI applications, so their exact
versions are not pinned. Secrets and private machine data never belong in
this repository.

## Bootstrap a Mac

During Setup Assistant, create the first macOS account with the short name
`gwku` and enable FileVault. Store its recovery key somewhere secure and
outside this repository. Then run:

```sh
xcode-select --install
git clone https://github.com/gwku/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./install.sh gkmp
```

After the installer succeeds, continue with the complete
[`POST-INSTALL.md`](POST-INSTALL.md) checklist. It covers the first restart,
Mac App Store and Bitwarden sign-in, SSH, privacy approvals, developer
credentials, SDKs, application data, code-managed macOS policy, and final
verification.

The installer:

1. installs Determinate Nix when necessary;
2. verifies that the configured macOS account exists;
3. uses the nix-darwin revision pinned by this flake;
4. activates nix-darwin and Home Manager.

The installer front-loads macOS administrator authentication and keeps that
authorization alive during the build. If Xcode command-line tools are
missing, it starts Apple's installer and asks you to rerun after it
finishes. If the Bitwarden CLI is already configured but locked, its unlock
also happens before the long switch starts. Once preflight is complete, the
Nix/Homebrew activation itself is non-interactive.

End-to-end bootstrap is not completely unattended: Mac App Store
applications require an Apple ID sign-in and the separate command below,
and a clean machine still needs one-time Bitwarden desktop/CLI login and
SSH-agent setup after activation. FileVault enrollment belongs in Setup
Assistant because it creates credential-bound recovery material; the runtime
test verifies that it remains enabled.

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

## Maintenance and updates

These commands are not a daily routine. Normal computer use requires no
Nix maintenance. Run them only after changing or pulling this repository,
when deliberately updating pinned dependencies, or when troubleshooting.

```sh
# Test changes without activating them
./scripts/check.sh gkmp

# Apply repository changes to this Mac
./scripts/switch.sh gkmp

# Periodically update pinned Nix inputs, test, and then apply
nix flake update
./scripts/check.sh gkmp
./scripts/switch.sh gkmp

# Troubleshooting: inspect or roll back to an older Mac generation
darwin-rebuild --list-generations
sudo darwin-rebuild --switch-generation <generation>
```

Fish provides a few optional abbreviations:

- `drs` applies this Mac's configuration (macOS only);
- `hms` applies the standalone Home Manager configuration (Linux only);
- `nfu` updates the repository's pinned Nix inputs;
- `nfc` checks the repository's flake.

The abbreviations use the repository at `~/development/dotfiles`, so they
work from any directory. Updating inputs can change many package versions;
review `flake.lock`, run the checks, and switch only when you intend to
upgrade.

When the switch script is launched from a root shell, Bitwarden preflight
still runs as the Mac's configured primary user. Maccy preference restoration
is attempted by Home Manager; a macOS app-data permission denial warns and
allows the rest of activation to complete. From a terminal permitted to
access Maccy app data, run `restore-maccy-preferences` as your normal user,
then rerun the smoke test. The smoke test continues to fail until Maccy's
declared preferences can be verified.

The Homebrew declaration is exhaustive: activation runs an explicit,
non-zapping `brew bundle cleanup --force`, so formulae and casks removed
from the declaration are also removed from the machine while their user
data is preserved. Close Homebrew-managed applications before switching.

Activation checks application bundles before and after Homebrew runs.
An interrupted cask upgrade can leave an empty `.app` directory that
`brew bundle` would otherwise adopt. Reinstall any reported casks with
`brew reinstall --cask <cask>`, then retry the switch. The same check is
available as `./scripts/check-macos-apps.sh` and in the runtime smoke test.

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
- synchronizes metadata in the switch preflight, prompting before the build
  when the CLI is logged in but locked.

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

`scripts/switch.sh` prompts for `bw unlock` before building when the CLI is
logged in but locked. Home Manager activation always uses the
non-interactive mode, preserving the last generated configuration when the
CLI is locked, has never logged in, or returns an API error. Failed optional
syncs warn without blocking the switch; rerun `bw-ssh-sync` after resolving
the CLI error. The repository contains neither secret blobs nor vault
credentials.

## Forgejo CLI for coding agents

`forgejo-cli` is declared in the Homebrew formula list and provides `fj`. The
pinned nixpkgs package is older than T3's supported CLI, so macOS uses Homebrew.
A Home Manager wrapper exposes `fj` on the Nix profile PATH used by GUI agents.
The current machine also has these two wrapper packages in its user Nix profile;
a full system switch is not required just to make the CLI available.

Git fetch/push continues through the Bitwarden SSH agent. PRs, reviews and
Actions status use a separate Forgejo API login. Once the MC agent credential
has been provisioned in restricted Infisical, initialize or refresh that login:

```sh
fj version
mc-forgejo-login
fj --host https://git.marketingconcurrent.nl whoami
```

The helper reads only `FORGEJO_AGENT_TOKEN` from Forgejo Administration,
Production `/`, validates the expected account and passes the token to `fj`
through stdin. It does not print credentials. The CLI's local credential file
is mode 600 in a mode-700 directory. Infisical remains the source for rotation;
run the helper again after a rotation. No token is embedded in this repository
or the Nix store. The approved token uses gwku's existing repository access,
with repository/issue write and user/organization read scopes; it has no
site-administration API scope. Forgejo 17 cannot combine the CLI's required
user-read scope with an explicit repository allowlist. An Infisical CLI login with access to that restricted project
is required; application CI identities do not get access.

`fj` 0.7.0 can show Actions run status (`fj actions tasks`) but has no log
command. Forgejo 17's REST API does, so `mc-forgejo-logs` reads logs with the
login `mc-forgejo-login` already stored (read-only, fixed host, no extra
scope):

```sh
mc-forgejo-logs list                  # recent runs, from the repo's origin remote
mc-forgejo-logs                       # failed jobs of the latest failed run, last 200 lines each
mc-forgejo-logs 5 --tail 0            # failed jobs of run #5, full log
mc-forgejo-logs 5 --all -q error      # every job, only lines containing "error"
mc-forgejo-logs 5 --job 178 --step 3  # one job, one step
```

Run numbers are the ones shown in the UI and `fj`. Log text is untrusted CI
output. Remove the helper once `fj` ships a native log command.

The `mchub-task` skill in McHub contains the shipping workflow. Authentication
does not authorize deployment: preserve the task's explicit go-ahead and current
head checks. `gh` continues to handle GitHub repositories, including backup
inspection, and is not the client for the canonical MC Forgejo PRs.

## MC GitHub backup push guard

The Git configuration rejects pushes to MarketingConcurrent's normal GitHub
HTTPS, SSH and Git URLs. Forgejo is canonical; use its `origin` for commits and
PRs. GitHub backup fetches and other GitHub organizations are unaffected. This
works with GitHub Free and applies to new clones after activation.

An explicit `remote.<name>.pushurl` bypasses Git's `pushInsteadOf` rewriting.
Existing MC backup remotes therefore also use a deliberately blocked push URL:
`github-backup-push-blocked://MarketingConcurrent/<repo>.git`. A direct GitHub
URL push is covered by the global rewrite. This is an accidental-push guard on
machines using these dotfiles, not a GitHub server security boundary: an owner
can intentionally override local Git configuration. Ordinary GitHub collaborators
must separately have read-only repository access. GitHub Free private repositories
cannot enforce an owner-excluding branch/tag ruleset.

## Agent skills for Claude Code and Codex

[`modules/home/agent-skills/`](modules/home/agent-skills/) installs every
folder under its `skills/` directory (each with a `SKILL.md`) into both
`~/.claude/skills` and `~/.codex/skills` on every switch. To add a skill, drop
its folder into `modules/home/agent-skills/skills/` and run
`./scripts/switch.sh`. Currently managed: `seo-2026`, an evidence-graded SEO
and AI-search audit workflow with a standard-library `scripts/seo_audit.py`.

The module copies with `rsync` instead of symlinking into the Nix store,
because skill discovery does not reliably follow symlinks in every tool
version. Each managed skill folder is replaced as a whole (`--delete`), so edit
the copy in this repository rather than the installed one. Skills that are not
in the repository, such as `humanizer`, the synced Claude skills, and Codex's
`.system` set, are never touched.

## State restored outside Nix

Nix does not reproduce credentials, application databases, or cloud
accounts. Follow the ordered [`POST-INSTALL.md`](POST-INSTALL.md) checklist
after a clean bootstrap. [`UNMANAGED.md`](UNMANAGED.md) explains why that
state remains external. Important examples include:

- enabling Bitwarden's desktop SSH agent and running `bw-ssh-sync`;
- AWS, Kubernetes, GitHub CLI, GPG, and Stripe authentication;
- Android SDK platforms, system images, and accepted licences;
- application sign-ins and synced IDE/editor settings;
- network/peripheral enrollment and a credential-bound Time Machine
  destination.

Public Cursor extensions, Shopify CLI 4.5.2, and Google Lighthouse 13.4.1
are pinned by the flake. Cursor's bundled `anysphere.*` extensions continue
to ship with Cursor itself.

Home Manager uses the backup suffix `.hm-backup` when taking over an
existing file. Inspect those backups after the first successful switch
and remove them only after confirming the managed replacement works.

## Hosts

- `mbp16` — 16-inch Apple Silicon MacBook, named `GMBP16`
- `mbp14` — 14-inch Apple Silicon MacBook, named `GMBP14`
- `gkmp` — compatibility alias for `mbp16`
- `workstation` — x86-64 Linux placeholder

Select the matching Mac explicitly when installing, for example
`./install.sh mbp14`. `./scripts/switch.sh` and `drs` select `mbp14` or `mbp16`
from the Mac's LocalHostName, accepting both the original `MBP14`/`MBP16`
and current `GMBP14`/`GMBP16` names; an explicit argument overrides that selection.
Both Macs share their software configuration; their separate targets preserve
their names across activation. Unknown Mac names retain the `gkmp` default.

## .NET SDKs

On macOS, Homebrew manages `dotnet-sdk` and `dotnet-sdk@8` in the same
`/usr/local/share/dotnet` installation. Updates run during the normal system
switch (`homebrew.onActivation.upgrade = true`), or manually with
`brew update && brew upgrade --cask dotnet-sdk dotnet-sdk@8`.
Homebrew does not run background updates on its own.

Nix supplies only a `dotnet` launcher pointing at that installation, so its
PATH precedence cannot hide the Homebrew SDKs. `DOTNET_ROOT` points there
for app hosts and editors too. McHub requires SDK 10.0.4xx for its preview
C# collection expression arguments; the runtime smoke test checks this.

On Linux, Nix combines both SDKs. `packages/dotnet/releases.nix` vendors
upstream Nixpkgs release metadata with pinned Microsoft download hashes for
SDK 10.0.403 while the rest of Nixpkgs stays on the existing lockfile.

After switching, check for an old `dotnet-wrapped-combined` user-profile
override. Remove it only if it appears in `nix profile list`; otherwise
there is nothing to remove. An old SDK override would hide the managed
launcher:

```sh
./scripts/switch.sh gkmp
nix profile list
# Only if listed above:
nix profile remove dotnet-wrapped-combined
dotnet --list-sdks
```

An immediate repair may instead install the new `dotnet` launcher in the
user profile. It contains no SDK and does not pin Homebrew's versions;
after a full system switch it can be removed with `nix profile remove dotnet`.

## Node.js security updates

Apple Silicon and x86-64 Linux use the official Node.js 22.23.4 binaries, including its bundled security fixes,
from `packages/node-security`. Their SHA-256 hashes are pinned. The shell runtime, pnpm, and the
Shopify/Lighthouse wrappers use this package; other Nix packages stay on the existing lockfile.
The Darwin Node-tools build uses an independent executable temporary-path checker because the pinned Bash audit classifier crashes. The replacement rejects writable build-directory references and has regression tests.
The package retains the Node 22 major version. The Linux binary uses the standard Nix automatic ELF patching hook.

Build and temporarily select the patched runtime before a full system activation:

```sh
nix build .#node-security
nix profile install .#node-security
node --version
```

Apply the managed shell and CLI wrappers with the normal `darwin-rebuild switch --flake .#gkmp`.
Once that activation is complete, remove the temporary `node-security` user-profile entry
with `nix profile remove node-security pnpm-security` so the managed system remains the source of truth.
