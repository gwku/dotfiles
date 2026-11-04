T3 Code supports Forgejo/Gitea through `fj` 0.6 or newer (or `tea` 0.16 or
newer). These dotfiles install `fj`: Homebrew on macOS, Nix on Linux, or the
signed Arch/CachyOS package on Lenovo with
`bash scripts/install-forgejo-linux.sh`.

Use the host and account recorded in the private credential manager.
Authentication belongs to each machine's user account and is deliberately
excluded from Nix and Git. To add a token securely, pipe it to:

```sh
fj --host https://git.example.net auth add-token
```

With no token argument, `fj` reads the token from standard input. Avoid putting
tokens in command arguments or shell history. Use an existing token from the
password vault; the CLI stores it in its private user data directory.

Check installation and authentication with:

```sh
fj version
fj auth list
fj --host https://git.example.net user view
```

On macOS, credentials are in
`~/Library/Application Support/forgejo-cli.forgejo-cli/keys.json`; on Linux,
they are in `~/.local/share/forgejo-cli/keys.json`. Keep this file mode 600 and
never commit it. Adding a host does not change existing Git remotes.

T3's running server needs `fj` on its process PATH. Both Macs include
`/opt/homebrew/bin`; Lenovo includes `/usr/bin`. Installing there lets the
existing server discover the CLI without interrupting active threads. Refresh
the Forgejo/Gitea capability in T3 after installation/authentication.
