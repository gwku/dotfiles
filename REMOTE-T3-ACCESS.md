# T3 access across devices

Devices enroll with the coordination server recorded in the private inventory.
Store device names, mesh addresses, SSH aliases, and controller URLs outside
this public repository. Mesh traffic uses WireGuard; routing internet traffic
through an exit node is a separate opt-in configuration.

The native Android app supports these HTTP endpoints inside the encrypted mesh.
The hosted web client requires HTTPS. Android browser/device video also needs a
secure endpoint; ordinary chat access and pairing do not require a public gateway.

## Android enrollment and pairing

In the official Tailscale Android app, select Accounts → the three-dot menu →
Use an alternate server, and enter the private coordination-server URL. Register the pending
device under the existing Headscale user using Headplane or the command shown
by the registration page. Keep Tailscale connected when away from home.

In T3, add each laptop separately under Settings → Environments. On each host,
create a fresh pairing link, using its mesh address:

```sh
~/.t3/bin/t3 auth pairing create \
  --base-dir "$HOME/.t3" \
  --base-url http://MESH_IP:3773 \
  --label 'phone' --ttl 5m
```

Replace the address for the other Mac or Lenovo; Lenovo's CLI is `~/.local/bin/t3`.
Scan the host's QR code from T3's pairing screen or paste its pairing link.
Pairing links are credentials: never commit, log, or share them publicly. They
expire independently of the device session established by pairing. Revoke a
lost phone's sessions in T3 on each host and remove its node in Headplane.

The host must be awake, unlocked after reboot, and running T3. Lenovo runs a
user service; both Macs currently use their desktop app. FileVault/LUKS unlock
still requires someone at the laptop after a reboot.

Android normally allows one VPN app at a time. Switch between Tailscale and
the FRITZ!Box WireGuard app as needed; they cannot ordinarily stay active
together on the phone. macOS and Linux can use the separate routes together.

## Laptop links

The desktop client's saved environments and the server's agent links are
separate. On each Mac, Settings → Environments includes the other two machines
alongside the local server. Add them through Remote link or SSH using the
existing aliases. Each desktop keeps its own encrypted connection catalog;
the official pairing flow saves it after local confirmation. Do not copy this
catalog between computers or put it in dotfiles.

Lenovo runs its existing headless server continuously and a separate desktop
client with its embedded local server disabled. Its client pairs with all
three existing servers, including its own. Reproduce the desktop installation
without disturbing that server using:

```sh
./scripts/install-t3code-desktop-linux.sh --client-only
./scripts/install-t3code-desktop-linux.sh --check
```

The installer verifies the official pinned AppImage and extracts it to avoid
the Lenovo's old AppImageLauncher/FUSE interception. It retains Chromium's
sandbox and registers desktop launchers and pairing protocols.

T3's displayed machine names follow the operating system's friendly hostname.
A running server may cache its name until restarted. Saved client route names
may require refreshing through the application's own connection flow.

Use authenticated T3 endpoints on the private mesh as the primary agent-link
routes. Restrict their listeners with the mesh ACL and host firewall. This
keeps paired agent access independent of an SSH agent's unlock prompt.
Optional Home Manager SSH forwards provide loopback fallback routes:

Local and reverse port mappings belong in the private peer configuration.
Do not publish a live device-to-port inventory here.

The reverse forwards let Lenovo reach the Macs without copying their SSH
private keys onto Lenovo. The Mac whose app is being accessed must keep its
tunnel to Lenovo running. Bitwarden must expose the SSH key through its
desktop agent when a tunnel reconnects.

Start links with approval-required access; grant full access only where the
user explicitly approves it. Set a direct mesh URL as the primary route and
an optional loopback fallback with the CLI's repeated `--url` flag. T3
environment links last 30 days; renew using a fresh pairing code. The phone
uses direct mesh addresses, never another computer's localhost ports.

Portable settings and keybindings come from `modules/home/t3-code`. Each
machine keeps its own identity, credentials, SQLite state, projects, and
session history. Git synchronizes source repositories independently.

References:

- [T3 remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md)
- [Tailscale custom coordination servers](https://tailscale.com/docs/how-to/set-up-custom-coordination-server?tab=android)
