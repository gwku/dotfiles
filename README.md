# dotfiles

Declarative Nix configuration for macOS (nix-darwin + Home Manager) and Linux (standalone Home Manager). Fish shell, WezTerm, Neovim. No Homebrew. No secrets in this repo — ever.

## Bootstrap

```sh
git clone https://github.com/gwku/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles
./install.sh <hostname>
```

The installer detects platform, installs Nix via the Determinate Systems installer if missing, then applies the flake.

## Daily-driver commands

| | macOS | Linux |
|---|---|---|
| Switch | `darwin-rebuild switch --flake ~/development/dotfiles#<host>` | `home-manager switch --flake ~/development/dotfiles#gwku@<host>` |
| Build only | `darwin-rebuild build --flake .#<host>` | `home-manager build --flake .#gwku@<host>` |
| Check | `nix flake check` | `nix flake check` |
| Update inputs | `nix flake update` | `nix flake update` |
| Rollback | `darwin-rebuild --switch-generation <n>` | `home-manager generations` |

Fish abbreviations `drs` and `hms` are wired up for the switch commands.

## Hosts

- `gkmp` — current MacBook (Apple Silicon)
- `workstation` — Linux placeholder

## Secrets policy

**Nothing sensitive is ever committed.** Long-term decryption risk (AI/quantum) makes encrypted-in-repo a non-starter.

| Type | Where it lives | How it gets there |
|---|---|---|
| SSH keys | `~/.ssh/id_*` (chmod 600) | Placed manually post-bootstrap |
| API tokens, env vars | `~/.config/fish/conf.d/secrets.fish` | Populated manually; sourced by fish |
| Git signing key | GPG / ssh-agent | Managed outside Nix; only the key ID is in `programs.git.signing.key` |
| Ad-hoc fetches | Bitwarden vault via `bw` CLI | Run `bw-load-secrets` to unlock and export to current shell |

No sops-nix, no agenix, no encrypted blobs anywhere in the tree.

## Unmanaged apps

See [`UNMANAGED.md`](UNMANAGED.md) for macOS GUI apps that need manual install (OrbStack, JetBrains Toolbox, etc.).
