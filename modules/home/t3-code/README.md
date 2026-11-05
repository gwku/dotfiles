# Portable T3 configuration

The repository contains reviewed public defaults. Runtime preference changes,
peer inventory, credentials, and private instructions never get exported to Git.

`sync-portable-settings.py` merges the reviewed defaults into writable T3 files.
It preserves provider/secret/device configuration, identities, migration markers,
browser profiles, per-project overrides, onboarding, authorization records,
databases, and window geometry. Changed files receive a private timestamped
backup before atomic replacement. All 86 reviewed keybindings include the four
upstream F6 workspace-navigation defaults on every platform.

## Automatic private preferences

One selected computer is the authority. A 30-second user job exports only
reviewed simple preferences from that computer and distributes them through
existing SSH aliases. Changes made on the authority therefore propagate while
the computers are reachable. The job does not commit, push, or modify templates.

Private configuration lives at `~/.config/t3-private/peers.json` (mode 0600):

```json
{
  "settingsSync": {
    "enabled": true,
    "authority": true,
    "peers": [{ "sshAlias": "example-peer" }]
  },
  "tunnels": []
}
```

Enable authority on exactly one computer. Other computers keep it false.
Runtime payload, delivery status, and receipts live under
`${XDG_STATE_HOME:-~/.local/state}/t3-portable-sync/`, outside Git. Peer
configuration is read at runtime and is never copied into the Nix store.

The automatic allowlist covers ordinary UI/editor/composer/browser preferences,
model choices using standard built-in provider IDs, cleanup behavior, worktree
behavior, update checks, activity profile, writing-style mode/template preference,
and simple keybindings. It excludes private prompts/instructions, custom provider
identities/configuration, model weights keyed by private providers, custom paths
and URLs, browser profiles, authorizations, catalogs, and transient view state.

Each receiver compares a preference against its last applied receipt. If someone
changed it locally, the job preserves that edit and records a conflict rather
than overwriting it. Offline computers are retried later. Only the conflicting
preference pauses; independent safe changes still apply. Inspect private
`status.json` and intentionally reconcile a conflict with the authority's value.
This is one-authority replication, not ambiguous last-writer-wins synchronization.

Once private synchronization is initialized, Home Manager only seeds missing
public defaults; subsequent switches do not restore old template values over
current UI changes. A new installation starts with the reviewed public defaults.

Server preferences are watched and update live. The current upstream desktop
hydrates client preferences only once: changes delivered to `client-settings.json`
need a frontend/app reload before an already-open GUI adopts them. The job never
forces a reload that could interrupt work. It records `clientReloadRequired` and
a private reload reminder when that file changes. After reloading, clear the
reminder with `t3-private-sync --ack-client-reload`. Editing settings in a still
cached receiver GUI can write old values back; those become reported conflicts
rather than silently overwriting user choices. Full live frontend synchronization
requires upstream application support.

Run `t3-private-sync` to deliver immediately. The native script can also be run
with `python3 modules/home/t3-code/private-sync.py`.

## Private loopback forwards

`t3-ssh-tunnel` maintains all configured forwards with reconnect/backoff and
loopback-only listeners. Its generic private peer records have this shape:

```json
{
  "selfHostName": "this-node",
  "selfServerPort": 3773,
  "tunnels": [{
    "sshAlias": "example-peer",
    "selfHostName": "peer-node",
    "localPort": 5000,
    "remotePort": 3773,
    "reversePortBySelfHostname": { "this-node": 6000 }
  }]
}
```

The manager skips its own node, validates aliases/ports, reloads changed tunnel
configuration, and keeps one SSH connection per peer carrying both directions.
Reverse forwards let a peer reach this computer without copying its private SSH
keys. `BatchMode` avoids interactive password prompts; an unavailable/locked SSH
agent can leave SSH waiting for signing approval. Prefer direct authenticated
mesh routes for agent links, with these forwards as optional fallbacks.
Run `t3-ssh-tunnel --validate` before
activation. A user LaunchAgent or systemd user unit owns the manager.

## Scope and view state

Each environment owns its projects/checkouts, credentials, sessions, databases,
and encrypted desktop connection catalog. Link environments through T3 to make
their project union accessible; registering an existing directory does not clone,
copy, or synchronize its working tree.

T3 stores Usage's time-window selection, theme selection, open tabs/panels,
widths, drafts/stashes, terminal sessions, caches, UI dismissals, and analytics IDs
in each frontend's local storage. There is currently no supported general import
API for that storage. These jobs do not edit/copy SQLite or LevelDB files. Choose
Usage's desired period once in each client UI. System appearance and built-in
themes require no shared custom palette in this configuration.

Application version pins/installers are separate from preference replication.
Use official checksummed releases and preserve the userdata/catalog during an
upgrade. Restarting a backend interrupts its active work; coordinate it first.
