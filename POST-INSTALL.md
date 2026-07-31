# First Mac post-install checklist

Use this checklist after `./install.sh gkmp` finishes successfully on a new
Mac. Nix has already installed the declared applications, command-line tools,
fonts, Dock layout, shell, editor configuration, and portable application
preferences. The remaining work requires accounts, credentials, hardware,
macOS privacy approval, or machine-local data and therefore cannot safely run
unattended.

Run commands from:

```sh
cd ~/development/dotfiles
```

Skip optional services and applications that are not relevant on the new
machine. Never copy credentials, private keys, tokens, private host metadata,
or encrypted secret blobs into this repository.

## 1. Restart and confirm the baseline

- [ ] Restart the Mac once so the Nix daemon, login shell, Dock, launch
      services, and macOS privacy subsystem all begin from a clean session.
- [ ] Open WezTerm from the Dock and confirm that Fish, the prompt, colours,
      font, and keybindings load.
- [ ] Confirm that the Dock contains the expected applications and no recent
      applications or unwanted right-side shortcuts.
- [ ] Run the initial runtime check:

```sh
./scripts/smoke-test.sh
```

Resolve any smoke-test failure before restoring accounts or local data.

## 2. Finish App Store setup

- [ ] Sign into the Mac App Store.
- [ ] Install all declared App Store applications:

```sh
./scripts/install-mas-apps.sh
```

This restores Amphetamine, HP Smart, Keynote, Microsoft Word, Numbers, Pages,
Todoist, and WireGuard.

## 3. Restore Bitwarden and SSH

- [ ] Open Bitwarden, sign in, unlock the vault, and allow it to run in the
      background.
- [ ] In Bitwarden settings, enable the desktop SSH agent.
- [ ] Log the CLI into the same account:

```sh
bw login
```

- [ ] Generate public selectors and SSH host configuration from native
      Bitwarden SSH items:

```sh
bw-ssh-sync
```

- [ ] Verify that the agent exposes the expected public keys and that the
      generated configuration parses:

```sh
ssh-add -L
ssh -G github.com
```

- [ ] Test GitHub and at least one private host alias:

```sh
ssh -T git@github.com
ssh <private-host-alias>
```

GitHub reports successful authentication without providing a shell. Approve
the Bitwarden request when a key is used for the first time. Do not restore
old private-key files or `~/.ssh/config.local`; Bitwarden is the source of
truth.

- [ ] Run a normal switch once more now that Bitwarden is configured. This
      proves that the standard preflight unlock and metadata sync work:

```sh
./scripts/switch.sh gkmp
```

## 4. Approve privacy permissions and startup applications

Open each relevant application once and grant only the permissions it
actually requests.

- [ ] Approve Accessibility/Input Monitoring where requested by Easy
      Move+Resize, Maccy, Ice, and Scroll Reverser.
- [ ] Approve microphone, camera, and screen-recording access for OBS and
      communication/AI applications that need those features.
- [ ] If OBS Virtual Camera is needed, approve its system extension in
      **System Settings → General → Login Items & Extensions**.
- [ ] Complete any Elgato Wave Link driver or system-extension approval.
- [ ] Confirm that Bitwarden and Nextcloud may run in the background.
- [ ] Confirm Elgato Wave Link, Ice, Maccy, Itsycal, Scroll Reverser, and
      Nextcloud started. Home Manager owns their LaunchAgents; they do not
      need to be added manually in Login Items.
- [ ] Leave OrbStack disabled at login. That policy is intentional.
- [ ] Arrange hidden and visible menu-bar items in Ice. Their positions are
      machine-local because macOS rewrites them.

## 5. Restore developer authentication

Complete only the services used on this machine. Prefer each tool's native
browser/device login and system credential storage over plaintext environment
variables.

- [ ] Authenticate GitHub CLI without creating another SSH key:

```sh
gh auth login --git-protocol ssh --skip-ssh-key
gh auth status
```

- [ ] Restore AWS profiles or configure IAM Identity Center:

```sh
aws configure sso
```

- [ ] Restore Kubernetes configuration from a secure source or authenticate
      with each cluster provider, then verify:

```sh
kubectl config get-contexts
```

- [ ] Restore GPG public/private keys from a secure backup, or reconnect the
      hardware security key that owns them.
- [ ] Authenticate Stripe:

```sh
stripe login
```

- [ ] Authenticate Infisical:

```sh
infisical login
```

- [ ] Authenticate Hugging Face if private or gated models are needed:

```sh
hf auth login
```

- [ ] Restore any required Cloudflare, container-registry, npm/pnpm,
      Composer, NuGet, database, Shopify, or other project-specific
      authentication.
- [ ] Verify that sensitive configuration such as `~/.aws`,
      `~/.kube/config`, `~/.gnupg`, and tool credential files is excluded from
      the dotfiles repository and protected with appropriate permissions.

## 6. Restore SDKs and IDE state

- [ ] Install the default Rust toolchain:

```sh
rustup default stable
```

- [ ] Open Android Studio's SDK Manager and restore the required SDK
      components. The previous machine used:

  - Android platforms 33 through 36;
  - build-tools 30.0.3 and the required 33 through 36.1 releases;
  - Android Emulator;
  - sources for Android 36;
  - an Android 36.1 system image.

- [ ] Accept Android SDK licences:

```sh
sdkmanager --licenses
```

- [ ] Recreate Android virtual devices rather than copying stale emulator
      lock/state files.
- [ ] Sign into Android Studio and enable settings sync.
- [ ] Sign into Rider, activate its licence, and enable JetBrains settings
      sync.
- [ ] Confirm the required JDKs and .NET SDKs are visible to both IDEs.

## 7. Restore application accounts and data

These items are deliberately outside Nix because they contain account state,
databases, personal data, device registrations, or large assets.

- [ ] Sign into Zen/Chrome/Firefox/Helium as needed and enable browser sync.
- [ ] Restore Thunderbird mail accounts or a private Thunderbird profile
      backup.
- [ ] Sign into Signal, WhatsApp, Telegram, Discord, and Slack; complete
      device linking where required.
- [ ] Sign into ChatGPT, Claude, Codex, Cursor, and other AI tools that are
      used.
- [ ] Connect Nextcloud and choose the local synchronization folders.
- [ ] Open the Obsidian vault from its restored or synchronized location.
- [ ] Sign into Todoist.
- [ ] Activate Microsoft Word and any other licensed Microsoft application.
- [ ] Open Amphetamine once and confirm its display-sleep, notification,
      menu-bar, and session defaults. Its historical statistics and sessions
      are intentionally not restored.
- [ ] Restore WireGuard tunnels from a secure backup.
- [ ] Restore Cyberduck bookmarks if needed; keep saved credentials in the
      system keychain or Bitwarden.
- [ ] Restore the Calibre library if used.
- [ ] Redownload only the LM Studio, Ollama, or Hugging Face models still
      needed. Models are intentionally not backed up by this repository.
- [ ] Restore OBS scenes/profiles from a private backup and remap audio/video
      devices. Do not commit stream keys or browser-source secrets.
- [ ] Restore UTM virtual machines and OrbStack machines/containers only when
      needed; their disk images and runtime state are not Nix-managed.
- [ ] Configure TeamViewer and Windows App accounts/devices if needed.
- [ ] Configure HP Smart, printer drivers, and the physical printer.
- [ ] Confirm Elgato Wave Link sees the attached hardware and restore any
      private hardware profile backup.

## 8. Install vendor-only applications

These do not currently have a suitable declarative installer:

- [ ] Install Little Snitch from the vendor and restore its rules from a
      private backup.
- [ ] Install any model-specific HP driver that HP Smart does not provide.

Reboot if a vendor system extension explicitly requires it.

## 9. Verify code-managed macOS policy

nix-darwin owns the portable macOS policy: USInternational-PC, automatic
appearance, text replacement and smart-quote behaviour, Dictation on,
Siri/Assistant off, Wi-Fi and Bluetooth power on, display sleep after two
minutes on battery and ten minutes on AC, Dock/Spaces behaviour, and the
startup applications listed above. Sudo uses the account password.

- [ ] Confirm that the code-managed policy passes its runtime assertions:

```sh
./scripts/smoke-test.sh
pmset -g custom
```

- [ ] If Time Machine is used, attach or select its destination once, then
      rerun `./scripts/switch.sh gkmp`; activation enables automatic backups
      whenever a destination exists. macOS may require Full Disk Access for
      the terminal performing that switch; a denied grant is reported without
      breaking the rest of activation.
- [ ] Pair required Bluetooth peripherals and add network credentials when
      needed. Device identities and credentials are enrollment state, not
      preference policy, and stay outside Git.
- [ ] Complete the first Time Machine backup after restoring personal data.

## 10. Restore local development work

- [ ] Clone personal and work repositories into `~/development`.
- [ ] Add non-secret, machine-specific paths or environment adjustments to:

```text
~/.config/fish/conf.d/local.fish
```

- [ ] Prefer native login/keychain files for secrets. If a tool absolutely
      requires shell environment variables, place them in the untracked local
      file below and restrict its permissions:

```text
~/.config/fish/conf.d/secrets.fish
```

```sh
chmod 600 ~/.config/fish/conf.d/secrets.fish
```

- [ ] Rebuild `terraform-provider-staticform` from
      `~/development/terraform-provider-staticform` if that project is
      restored.
- [ ] Recreate the `search-resoftware-customers` symlink from
      `~/development/resoftware-customers` if that private project is
      restored.
- [ ] Restore per-project `.envrc.local`, development databases, test data,
      and other private state from their appropriate secure sources.

## 11. Final verification

- [ ] Run the runtime test again:

```sh
./scripts/smoke-test.sh
```

- [ ] Confirm the main authentication and SDK state:

```sh
gh auth status
kubectl config get-contexts
rustup show active-toolchain
sdkmanager --list_installed
mas list
```

- [ ] Clone or fetch one GitHub repository over SSH.
- [ ] Test one Bitwarden-managed private SSH host.
- [ ] Launch the main Dock applications and confirm their managed settings
      loaded.
- [ ] Inspect any Home Manager migration backups and remove them only after
      verifying the managed replacements:

```sh
find ~/.config ~/.ssh \
  ~/Library/Application\ Support/Cursor \
  -name '*.hm-backup' -print 2>/dev/null
```

- [ ] Run a Time Machine backup after all account and project restoration is
      complete.

The machine is ready when the smoke test passes, Bitwarden-managed SSH and
GitHub work, required developer services are authenticated, required personal
data is restored, and the first backup has completed.

`scripts/finish-current-mac-cleanup.sh` is only for an old or migrated Mac
with legacy Docker privileged helpers. Do not run it on a genuinely clean
machine.
