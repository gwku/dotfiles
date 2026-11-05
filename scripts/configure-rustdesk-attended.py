#!/usr/bin/env python3
"""Merge a pinned private RustDesk server and attended policy into local settings.

Run while RustDesk is closed. This never reads/writes identity/password files,
installs a service, launches RustDesk, or changes OS privacy permissions.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import tempfile
import tomllib

POLICY = {
    "direct-server": "N",
    "approve-mode": "click",
    "access-mode": "custom",
    "enable-keyboard": "Y",
    "enable-clipboard": "N",
    "enable-file-transfer": "N",
    "enable-terminal": "N",
    "enable-tunnel": "N",
    "enable-camera": "N",
    "enable-audio": "N",
    "enable-remote-restart": "N",
    "allow-remote-config-modification": "N",
    "allow-only-conn-window-open": "Y",
    "enable-lan-discovery": "N",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--key", required=True, help="server PUBLIC signing key")
    parser.add_argument("--server", required=True, help="private server hostname from your private inventory")
    parser.add_argument("--config", type=Path)
    parser.add_argument("--enable-clipboard", action="store_true",
                        help="allow non-file clipboard sharing; file transfer stays disabled")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9+/]{43}=", args.key):
        parser.error("expected a base64 Ed25519 public key")
    if not re.fullmatch(r"[A-Za-z0-9.-]+", args.server):
        parser.error("server must be a hostname or IPv4 address without a port")
    config = args.config
    if config is None:
        import sys
        root = (Path.home() / "Library/Preferences/com.carriez.RustDesk"
                if sys.platform == "darwin" else
                Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "rustdesk")
        config = root / "RustDesk2.toml"
    original = config.read_text() if config.exists() else ""
    before = tomllib.loads(original)
    options = dict(before.get("options", {}))
    if not all(isinstance(v, str) for v in options.values()):
        raise ValueError("unexpected non-string RustDesk option; use the app UI")
    options.update(POLICY)
    if args.enable_clipboard:
        options.update({"enable-clipboard": "Y", "disable-clipboard": "N",
                        "one-way-clipboard-redirection": "N"})
    options.update({
        "custom-rendezvous-server": f"{args.server}:21116",
        "relay-server": f"{args.server}:21117",
        "key": args.key,
        "api-server": "",
    })
    section = re.search(r"(?m)^\[options\][ \t]*$", original)
    if section:
        following = re.search(r"(?m)^\[", original[section.end():])
        end = section.end() + following.start() if following else len(original)
        prefix, suffix = original[:section.start()], original[end:]
    else:
        prefix, suffix = original.rstrip() + "\n\n", ""
    table = "[options]\n" + "".join(
        f"{json.dumps(k)} = {json.dumps(v)}\n" for k, v in sorted(options.items()))
    updated = prefix + table + suffix
    after = tomllib.loads(updated)
    assert after == {**before, "options": options}, "unexpected change outside options"
    config.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if original and original != updated:
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        backup = config.with_name(config.name + ".before-attended-" + stamp)
        with open(backup, "x", opener=lambda p, f: os.open(p, f, 0o600)) as stream:
            stream.write(original)
    with tempfile.NamedTemporaryFile(mode="w", dir=config.parent, delete=False) as stream:
        temp = Path(stream.name)
        stream.write(updated)
    try:
        temp.chmod(0o600)
        temp.replace(config)
    finally:
        temp.unlink(missing_ok=True)
    print(f"Configured attended access at {config}; identity and peer history preserved")


if __name__ == "__main__":
    main()
