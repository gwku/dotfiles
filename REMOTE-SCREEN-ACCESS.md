# Remote screen access

Use RustDesk for the actual screen on macOS, Linux, and Windows. It is a
separate layer from T3: Headscale provides private reachability, and RustDesk
provides screen capture and keyboard/mouse control.

Use the private cluster context recorded in your private inventory. It has its own Headscale node, `rustdesk.mesh.example.net`, with
persistent node identity and server signing keys. It uses encrypted RustDesk
ID connections through that private node. The server forces its private relay,
so screen traffic follows the homelab mesh path rather than independent
peer-to-peer paths. No desktop service is published
through the home router, an Ingress, NodePort, or LoadBalancer.

## Client settings

In RustDesk Settings → Network → ID/Relay server:

- ID server: `rustdesk.mesh.example.net:21116`
- Relay server: `rustdesk.mesh.example.net:21117`
- Key: the public signing key from `/data/id_ed25519.pub` in the homelab
  `hbbs` container. Read the exact public key from the private server inventory.
  Pin this key on every client; do not leave it blank.
- API server: empty (the server uses the OSS protocol, not a Pro API).

With RustDesk closed, the helper merges the private server and attended policy,
preserving existing identity files, peer history, and other settings. Existing
options are backed up with mode 0600 before changes:

```sh
python3 scripts/configure-rustdesk-attended.py --server "$RUSTDESK_SERVER" --key "$RUSTDESK_PUBLIC_KEY"
```

It does not launch the app, install/start a service, or grant OS permissions.
The reference attended policy is:

| Setting | Value |
| --- | --- |
| `direct-server` | `N` |
| `approve-mode` | `click` |
| `access-mode` | `custom` |
| `enable-keyboard` | `Y` |
| `enable-clipboard` | `N` |
| `enable-file-transfer` | `N` |
| `enable-terminal` | `N` |
| `enable-tunnel` | `N` |
| `enable-camera` | `N` |
| `enable-audio` | `N` |
| `enable-remote-restart` | `N` |
| `allow-remote-config-modification` | `N` |
| `allow-only-conn-window-open` | `Y` |
| `enable-lan-discovery` | `N` |

Open RustDesk on the computer being reviewed, connect to its displayed
RustDesk ID from another laptop, and accept the request on the reviewed
computer. Use full-screen in the viewer. The reviewed computer keeps its
own active desktop; this does not create a second remote desktop session.

The default reference does not set a permanent password or enable unattended
access. A specific Linux machine can explicitly opt in as described below.
Client identities, passwords, peer history, and device privacy permissions
remain machine-local. Do not replace an existing RustDesk config file to
apply this reference: use the client UI or merge the specific options.

Direct-IP mode on TCP 21118 is intentionally disabled. RustDesk's direct-IP
path does not add application-level encryption; the private ID server
preserves RustDesk's encrypted connection protocol as well as the mesh's
WireGuard encryption.

## macOS

The Darwin module installs the official Homebrew cask. Before screen control
can work, the user must grant RustDesk **Screen Recording** and
**Accessibility** in System Settings → Privacy & Security. Some macOS
versions/input modes also need **Input Monitoring**. Full Disk Access is
not needed for ordinary screen sharing/control with file transfer disabled.
Do not reset or bypass macOS privacy controls with scripts.

The app may offer installation of its helper service. Installing a helper
and enabling incoming access is a separate consent step; installing the
cask does not enable it. With attended sharing, keep the RustDesk window
open and accept each session locally.

## Lenovo / Linux

Use both the native client window and the privileged input helper. The
attended policy rejects requests while the main window is closed, even if a
background service is running. Verify picture and input on the real desktop
before relying on it for remote assistance.

Linux is included in dotfiles. `modules/home/remote-desktop.nix` installs
`pkgs.rustdesk` through Home Manager on Linux. Its version follows the flake's
nixpkgs lock (currently 1.4.6). This installs the client without enabling a root
service or changing permissions, credentials, or session approval during switch.

The current CachyOS Lenovo uses the official native **1.5.1-0** Arch package,
which supplies the system input service needed for Wayland control. Reproduce
that installation without Nix using:

```sh
./scripts/install-rustdesk-linux.sh
./scripts/install-rustdesk-linux.sh --check
```

The installer pins the official GitHub asset and SHA256, verifies package metadata,
and suppresses the vendor scriptlets that would start against public defaults.
It installs the vendor service/desktop launchers, preserves existing customized
integration files, and reloads systemd/desktop metadata. It preserves local
identities, settings, and service enabled/running state. Repeated runs skip an
already installed matching or newer package; `--reinstall` reapplies 1.5.1 without
downgrading a newer version. It does not update the rest of Arch/CachyOS.

After installation, apply the private server and click policy **before** starting
sharing. The service has separate root settings, so configure both identities:

```sh
python3 scripts/configure-rustdesk-attended.py --server "$RUSTDESK_SERVER" --key "$RUSTDESK_PUBLIC_KEY"
sudo python3 scripts/configure-rustdesk-attended.py --config /root/.config/rustdesk/RustDesk2.toml --server "$RUSTDESK_SERVER" --key "$RUSTDESK_PUBLIC_KEY"
```

When the laptop owner approves attended sharing, explicitly activate the input
helper and launch the native GUI **from its logged-in graphical session**:

```sh
sudo systemctl enable --now rustdesk
/usr/bin/rustdesk
```

For reproducible graphical-login startup of the native RustDesk window and T3
desktop, run as the desktop user:

```sh
./scripts/install-linux-session-startup.sh --start
```

This installs user units bound to `graphical-session.target`; it does not
enable the root input helper, grant capture permissions, or remove click
approval. The root helper, T3 headless server, and graphical windows are
separate services. Closing the RustDesk window intentionally blocks attended
connections; reopen it or restart `rustdesk-gui.service` when needed.

Service activation supplies privileged input support; click approval and the
open-window requirement still govern incoming sessions. It does not configure
an unattended password. Accept each incoming request and any Wayland screen
picker locally. To stop the helper and its startup at boot:
`sudo systemctl disable --now rustdesk`. The GUI and service have distinct roles:
the GUI must inherit the real session's Wayland/PipeWire environment. When both
Home Manager and native packages are installed, `/usr/bin/rustdesk` explicitly
selects the native client matching that helper.

On Wayland, the standard release shares a logged-in session using PipeWire
and XDG Desktop Portal. Use the backend matching the actual desktop, such
as `xdg-desktop-portal-hyprland` for this Lenovo's Hyprland session,
`xdg-desktop-portal-wlr` for Sway, KDE's backend for Plasma, or GNOME's
backend for GNOME. A local screen-selection/approval prompt may be
required. Do not switch the desktop or login manager to X11 merely to hide
this requirement.

The upstream unattended-Wayland preview currently targets x86_64
Debian/Ubuntu, not CachyOS. Do not promise unattended login-screen access on
this Lenovo until its real session has been tested.

No software remote-desktop tool can reach the Lenovo's LUKS unlock prompt
before Linux starts, or a Mac's FileVault preboot unlock screen. Those need
physical access or a separate hardware KVM.

## Restart and login

On macOS, Home Manager login agents open T3, RustDesk, and Bitwarden after
graphical login. The system Tailscale and firewall daemons run independently.
On Linux, the enabled T3 headless user service uses lingering; the desktop
window units start with the graphical session. Screen sharing needs that
logged-in session, a running RustDesk window, and local connection approval.

After a cold boot, unlock FileVault/LUKS locally first. Unlock Bitwarden and
approve SSH key use when a tunnel reconnects. Sleeping laptops may not answer
over the mesh. Service configuration and controlled app restarts do not prove
a full power-cycle test; record that separately after an attended reboot.

## Awake on external power

The Mac login configuration runs `caffeinate -s`, which inhibits system sleep
only on AC power and leaves display and battery preferences unchanged. It
does not guarantee closed-lid operation. Other applications can hold their
own independent sleep assertions.

For the native Linux installation, enable the conditional inhibitor once:

```sh
sudo install -D -m 755 scripts/keep-awake-on-ac.py /usr/local/libexec/t3-ac-awake.py
sudo install -D -m 644 scripts/t3-ac-awake.service /etc/systemd/system/t3-ac-awake.service
sudo systemctl daemon-reload
sudo systemctl enable --now t3-ac-awake
```

It polls external power, holds an idle/sleep inhibitor while plugged in, and
releases its inhibitor within three seconds on battery. It does not edit
battery settings or release inhibitors held by other active workloads. To
restore the previous policy, disable `t3-ac-awake` on Linux or unload the
Mac's `org.nix-community.home.t3-ac-awake` login agent and remove its declaration.

## Optional Linux password-only access

For an explicitly authorized machine, password-only authentication replaces
the local Accept prompt. First configure the private server, run its native
input service and graphical session, and save a strong unique permanent
password in your password manager. Supply it through a temporary owner-only
file outside Git, rather than a shell command or shell history:

```sh
sudo python3 scripts/configure-rustdesk-password-access.py \
  --expected-id "$RUSTDESK_TARGET_ID" --password-file "$PRIVATE_PASSWORD_FILE"
```

The helper checks the intended desktop ID and private-server configuration,
sets the password using the installed RustDesk CLI, then selects permanent
password authentication and removes the open-window requirement. It verifies
the result and preserves disabled clipboard, file transfer, terminal, tunnel,
camera and remote-configuration permissions. A local policy rollback record
is retained with administrator-only permissions. Remove the temporary password
file after configuration; never copy the plaintext into source or logs.

Reconnect from another client with the new password and verify that no Accept
click is needed. Clients may remember that password if desired. This does not
bypass disk unlocking, graphical login or Wayland's capture permission; screen
selection may be needed again after a new desktop session. Re-running the
attended helper explicitly restores its click/open-window policy.

## Verification

After grants and attended access are enabled:

1. Check `tailscale status` on both ends.
2. Confirm the private ID server is reachable on TCP 21116 and relay 21117.
3. Connect using the remote RustDesk ID and accept the session locally.
4. Verify the displayed screen, mouse movement, keyboard input, and
   multi-monitor/full-screen selection in both directions.
5. On the Lenovo, verify actual Wayland input and the portal screen prompt;
   a successful TCP connection alone does not verify screen control.

Upstream references:

- [RustDesk macOS permissions](https://rustdesk.com/docs/en/client/mac/)
- [RustDesk Linux / Wayland](https://rustdesk.com/docs/en/client/linux/)
- [Wayland unattended preview scope](https://www.rustdesk.com/blog/unattended-remote-access-wayland/)
- [Client policy options](https://rustdesk.com/docs/en/self-host/client-configuration/advanced-settings/)
- [Server OSS installation](https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/install/)
