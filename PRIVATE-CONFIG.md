# Private configuration and host firewalls

This repository is public. Keep credentials, device inventories, controller URLs,
real peer mappings, backup keys, pairing codes, and live runtime payloads outside
Git. The repository contains generic policy and reviewed preferences only.

## Local Nix extension

Darwin configurations optionally import `private.local.nix`. This filename is
ignored by Git. Restore it from a private backup before switching an enrolled
machine. Use it only for non-secret machine data, such as the mesh DNS domain:

```nix
{ ... }: { localMesh.magicDnsDomains = [ "mesh.example.net" ]; }
```

Nix copies evaluated configuration into its generally readable store. Never put
passwords, tokens, backup keys, or private SSH keys in any Nix module, including
ignored local modules. Use the credential manager or private runtime files.

The peer configuration in `~/.config/t3-private/peers.json` is different: it is
read at runtime, stays mode 0600, and is never embedded into the Nix store.
See `modules/home/t3-code/README.md` for its generic schema. Keep a private backup
of that file and the local Nix extension; public Git cannot restore them.

## macOS T3 boundary

The Darwin module enables Apple's application firewall and permits the existing
SSH, Tailscale and signed T3 executables. A separate PF anchor restricts incoming
TCP 3773 to loopback and the verified current Tailscale tunnel. It does not alter
SSH, developer ports, NAT or forwarding. A root launch daemon reevaluates the
tunnel and fails closed to loopback when the mesh is unavailable.

The helper validates and backs up `/etc/pf.conf` before inserting its own anchor
before Apple's filter anchors. It preserves existing unrelated rules. PF enable
references and rule backups are private under `/var/db/t3-mesh-firewall`.

Inspect the policy locally with administrator privileges:

```sh
sudo pfctl -a local.t3-mesh -sr
sudo pfctl -s References
```

To roll back only this one-port boundary, first stop its launch daemon, then
flush only the `local.t3-mesh` anchor. Do not flush global PF rules or states;
other software may own them. Backups retain the previous root configuration.

After applying, verify a fresh SSH connection, a loopback T3 connection, mesh
T3 access from another device, and rejection of direct LAN access to TCP 3773.
Keeping the HTTPS/controller connection reachable alone does not test this.

## Repository publishing

Review the staged diff and run a redacted secret scan before pushing. Ignored
runtime files must remain ignored; never use `git add -f` for them. Do not publish
private operational inventories merely because their values are not passwords.
