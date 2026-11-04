#!/usr/bin/env python3
"""Keep the macOS T3 listener reachable only over loopback and verified Tailscale.

Manages one PF anchor. It never changes SSH, forwarding, NAT or other ports.
No device addresses, enrollment data, or credentials are stored in this script.
"""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

ANCHOR = "local.t3-mesh"
STATE = Path("/var/db/t3-mesh-firewall")
PF = "/sbin/pfctl"
PORT = 3773


def run(args, *, content=None, check=True):
    result = subprocess.run(args, input=content, text=True, capture_output=True, timeout=15)
    if check and result.returncode:
        raise RuntimeError(f"{Path(args[0]).name} failed ({result.returncode})")
    return result


def interface(client):
    try:
        status = json.loads(run([client, "status", "--json"]).stdout)
        if status.get("BackendState") != "Running":
            return None
        for address in status.get("Self", {}).get("TailscaleIPs", []):
            ip = ipaddress.ip_address(address)
            if ip.version != 4 or ip not in ipaddress.ip_network("100.64.0.0/10"):
                continue
            route = run(["/sbin/route", "-n", "get", str(ip)]).stdout
            match = re.search(r"^\s*interface:\s*(utun[0-9]+)\s*$", route, re.M)
            if match:
                name = match.group(1)
                details = run(["/sbin/ifconfig", name]).stdout
                if re.search(r"(?<![0-9.])" + re.escape(str(ip)) + r"(?![0-9.])", details):
                    return name
    except (ValueError, RuntimeError, subprocess.TimeoutExpired, OSError):
        pass
    return None


def rules(name):
    lines = [f'pass in quick on lo0 proto tcp from any to any port {PORT} flags any keep state label "t3-loopback"']
    if name:
        if not re.fullmatch(r"utun[0-9]+", name):
            raise ValueError("Invalid verified tunnel interface")
        lines += [
            f'pass in quick on {name} inet proto tcp from 100.64.0.0/10 to any port {PORT} flags any keep state label "t3-mesh-v4"',
            f'pass in quick on {name} inet6 proto tcp from fd7a:115c:a1e0::/48 to any port {PORT} flags any keep state label "t3-mesh-v6"',
        ]
    lines.append(f'block drop in quick proto tcp from any to any port {PORT} label "t3-block-other"')
    return "\n".join(lines) + "\n"


def atomic_write(path, text, mode=0o600):
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(text)
    try:
        temporary.chmod(mode)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def attach_anchor():
    path = Path("/etc/pf.conf")
    original = path.read_text()
    statement = f'anchor "{ANCHOR}"'
    live = run([PF, "-sr"]).stdout
    if statement not in live:
        allowed = ('scrub-anchor "com.apple/', 'anchor "com.apple/', 'dummynet-anchor "com.apple/')
        if any(line.strip() and not line.lstrip().startswith(allowed) for line in live.splitlines()):
            raise RuntimeError("Unmanaged live PF filter rules; refusing a global reload")
        translations = run([PF, "-sn"]).stdout
        if any(line.strip() and not line.lstrip().startswith(('nat-anchor "com.apple/', 'rdr-anchor "com.apple/'))
               for line in translations.splitlines()):
            raise RuntimeError("Unmanaged live PF translation rules; refusing a global reload")
    if statement not in original.splitlines():
        # Insert ahead of Apple's filter anchors so their quick passes cannot
        # skip our one-port boundary. All scrub/NAT/rdr ordering is retained.
        apple = 'anchor "com.apple/*"'
        if apple not in original.splitlines():
            raise RuntimeError("Unrecognized PF configuration; leaving it unchanged")
        lines = original.splitlines(keepends=True)
        position = next(index for index, line in enumerate(lines) if line.rstrip("\r\n") == apple)
        lines.insert(position, statement + "\n")
        updated = "".join(lines)
        backup = STATE / ("pf.conf.before-" + str(time.time_ns()))
        atomic_write(backup, original)
        candidate = STATE / "pf.conf.candidate"
        atomic_write(candidate, updated)
        run([PF, "-n", "-f", str(candidate)])
        atomic_write(path, updated, 0o644)
        try:
            run([PF, "-f", str(path)])
        except Exception:
            atomic_write(path, original, 0o644)
            run([PF, "-f", str(path)], check=False)
            raise
    # A reboot or another PF owner can reload the original root ruleset.
    live = run([PF, "-sr"]).stdout
    if statement not in live:
        run([PF, "-f", str(path)])


def enable_reference():
    token_file = STATE / "enable-token"
    references = run([PF, "-s", "References"], check=False).stdout
    token = token_file.read_text().strip() if token_file.exists() else ""
    if token and re.search(r"\b" + re.escape(token) + r"\b", references):
        return
    result = run([PF, "-E"])
    match = re.search(r"Token\s*:\s*([0-9]+)", result.stdout + result.stderr)
    if not match:
        raise RuntimeError("PF did not return an enable reference")
    atomic_write(token_file, match.group(1) + "\n")


def apply(client):
    name = interface(client)
    desired = rules(name)
    path = STATE / "anchor.conf"
    changed = not path.exists() or path.read_text() != desired
    if changed:
        atomic_write(path, desired)
    run([PF, "-n", "-a", ANCHOR, "-f", str(path)])
    current = run([PF, "-a", ANCHOR, "-sr"]).stdout
    active_tunnels = set(re.findall(r"\bon (utun[0-9]+)\b", current))
    expected_tunnels = {name} if name else set()
    if changed or 'label "t3-block-other"' not in current or active_tunnels != expected_tunnels:
        run([PF, "-a", ANCHOR, "-f", str(path)])
    attach_anchor()
    enable_reference()
    return name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tailscale", required=True)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--render", metavar="INTERFACE", help="Print generic rules without requiring root")
    args = parser.parse_args()
    if args.render:
        print(rules(None if args.render == "none" else args.render), end="")
        return
    if os.geteuid() != 0:
        parser.error("Root is required to manage the PF anchor")
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    STATE.chmod(0o700)
    while True:
        name = apply(args.tailscale)
        if args.once:
            print("T3 ingress policy active: " + ("mesh and loopback" if name else "loopback only"))
            return
        time.sleep(5)


if __name__ == "__main__":
    main()
