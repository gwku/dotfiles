#!/usr/bin/env bash
# Maintain loopback-only T3 forwards using private, machine-local peer data.
set -euo pipefail
exec python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--config', type=Path, default=Path.home() / '.config/t3-private/peers.json')
parser.add_argument('--validate', action='store_true')
args = parser.parse_args()

def read_config():
    if not args.config.exists():
        return {'tunnels': []}
    config = json.loads(args.config.read_text())
    tunnels = config.get('tunnels', [])
    if not isinstance(tunnels, list):
        raise ValueError('Private tunnels must be a list')
    ports = set()
    for peer in tunnels:
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.@-]*', peer['sshAlias']):
            raise ValueError('Invalid private SSH alias')
        for key in ['localPort', 'remotePort']:
            if not isinstance(peer[key], int) or not 1024 <= peer[key] <= 65535:
                raise ValueError('Invalid private tunnel port')
        if peer['localPort'] in ports:
            raise ValueError('Duplicate local tunnel port')
        ports.add(peer['localPort'])
        for value in peer.get('reversePortBySelfHostname', {}).values():
            if not isinstance(value, int) or not 1024 <= value <= 65535:
                raise ValueError('Invalid private reverse port')
    return config

config = read_config()
if args.validate:
    print('Private tunnel configuration valid')
    raise SystemExit(0)
if not config.get('tunnels'):
    raise SystemExit(0)

stopping = False

def stop(_signal, _frame):
    global stopping
    stopping = True

signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
children = {}
next_attempt = {}
last_config = None


def terminate(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()

try:
    while not stopping:
        try:
            new = read_config()
            signature = hashlib.sha256(json.dumps({k: new.get(k) for k in ['tunnels', 'selfHostName', 'selfServerPort']}, sort_keys=True).encode()).hexdigest()
            if signature != last_config:
                for child in children.values():
                    terminate(child)
                children.clear()
                next_attempt.clear()
                config = new
                last_config = signature
            self_name = config.get('selfHostName')
            if not self_name:
                status = subprocess.run(['tailscale', 'status', '--json'], check=True, capture_output=True, text=True, timeout=10)
                self_name = json.loads(status.stdout)['Self']['HostName']
            desired = []
            for index, peer in enumerate(config.get('tunnels', [])):
                if peer.get('selfHostName') == self_name:
                    continue
                desired.append(index)
                child = children.get(index)
                if child is not None and child.poll() is None:
                    continue
                if child is not None:
                    next_attempt[index] = time.monotonic() + 15
                    del children[index]
                if time.monotonic() < next_attempt.get(index, 0):
                    continue
                command = ['ssh', '-N', '-T', '-o', 'BatchMode=yes', '-o', 'ExitOnForwardFailure=yes',
                           '-o', 'ConnectTimeout=8', '-o', 'ConnectionAttempts=1',
                           '-o', 'ServerAliveInterval=30', '-o', 'ServerAliveCountMax=3',
                           '-o', 'ControlMaster=no', '-o', 'ControlPath=none', '-o', 'ForwardAgent=no',
                           '-L', f"127.0.0.1:{peer['localPort']}:127.0.0.1:{peer['remotePort']}"]
                reverse = peer.get('reversePortBySelfHostname', {}).get(self_name)
                if reverse:
                    command += ['-R', f"127.0.0.1:{reverse}:127.0.0.1:{config.get('selfServerPort', 3773)}"]
                command.append(peer['sshAlias'])
                children[index] = subprocess.Popen(command)
            for index in list(children):
                if index not in desired:
                    terminate(children.pop(index))
        except (OSError, ValueError, KeyError, subprocess.SubprocessError):
            # Never log private peer inventory, credentials, or source JSON.
            print('Private tunnel setup unavailable; retrying', flush=True)
        for _ in range(15):
            if stopping:
                break
            time.sleep(1)
finally:
    for child in children.values():
        terminate(child)
PY
