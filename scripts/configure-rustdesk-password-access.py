#!/usr/bin/env python3
"""Opt in to macOS/Linux RustDesk password-only access using its installed CLI.

Supply a temporary owner-only password file; never pass the password in a
shell command or commit it. Configure the pinned private server first.
"""
import argparse
import datetime
import json
import os
import pwd
from pathlib import Path
import stat
import subprocess
import sys


CLI = ('/Applications/RustDesk.app/Contents/MacOS/RustDesk'
       if sys.platform == 'darwin' else '/usr/bin/rustdesk')
POLICY = {
    'verification-method': 'use-permanent-password',
    'approve-mode': 'password',
    'allow-only-conn-window-open': 'N',
}
DISABLED = ['direct-server', 'enable-file-transfer',
            'enable-terminal', 'enable-tunnel', 'enable-camera',
            'allow-remote-config-modification', 'enable-remote-restart']


def cli(*arguments):
    environment = os.environ.copy()
    if sys.platform == 'darwin':
        # macOS sudo can preserve the caller's HOME. Root CLI startup must
        # not create root-owned cache/config files in the desktop user's home.
        environment.update(HOME=pwd.getpwuid(0).pw_dir, USER='root', LOGNAME='root')
    result = subprocess.run([CLI, *arguments], env=environment,
                            capture_output=True, text=True, timeout=15)
    if result.returncode:
        raise RuntimeError('RustDesk CLI request failed; sensitive output suppressed')
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--password-file', required=True, type=Path)
    parser.add_argument('--expected-id', required=True, help='ID displayed by the target desktop')
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error('run as administrator for the installed input service')
    descriptor = os.open(args.password_file, os.O_RDONLY | os.O_NOFOLLOW)
    with os.fdopen(descriptor) as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077:
            parser.error('password file must be a regular owner-only file')
        password = stream.read(4097).rstrip('\r\n')
    if not 12 <= len(password) <= 4096 or any(c in password for c in '\r\n\x00'):
        parser.error('use a unique password of at least 12 characters on one line')
    if cli('--get-id').replace(' ', '') != args.expected_id.replace(' ', ''):
        parser.error('CLI identity differs from the intended desktop; no changes applied')
    if not cli('--option', 'custom-rendezvous-server') or not cli('--option', 'key'):
        parser.error('configure the pinned private server before unattended access')
    for option in DISABLED:
        if cli('--option', option) != 'N':
            parser.error('expected existing disabled permission: ' + option)
    clipboard_before = cli('--option', 'enable-clipboard')
    if clipboard_before not in {'Y', 'N'}:
        parser.error('unexpected clipboard permission; no changes applied')
    before = {option: cli('--option', option) for option in POLICY}
    backup_dir = Path('/var/db/t3-rustdesk-policy' if sys.platform == 'darwin'
                      else '/var/lib/t3-rustdesk-policy')
    backup_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    backup = backup_dir / (stamp + '.json')
    with open(backup, 'x', opener=lambda p, f: os.open(p, f, 0o600)) as stream:
        json.dump(before, stream, indent=2)
    # The installed CLI routes these requests to the logged-in user's server.
    # Set a usable password before changing approval policy. Never echo it.
    if 'Done!' not in cli('--password', password):
        raise RuntimeError('Permanent password was not set; approval policy unchanged')
    try:
        for option, value in POLICY.items():
            cli('--option', option, value)
            if cli('--option', option) != value:
                raise RuntimeError('RustDesk did not retain the requested policy')
        for option in DISABLED:
            if cli('--option', option) != 'N':
                raise RuntimeError('A disabled permission changed unexpectedly')
        if cli('--option', 'enable-clipboard') != clipboard_before:
            raise RuntimeError('Clipboard permission changed unexpectedly')
    except Exception:
        for option, value in before.items():
            cli('--option', option, value)
        raise
    print('Password-only access configured; private server and disabled permissions preserved')
    print('Local policy rollback record:', backup)


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        raise SystemExit(type(error).__name__ + ': operation failed; no password output') from None
