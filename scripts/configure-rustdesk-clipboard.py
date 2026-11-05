#!/usr/bin/env python3
"""Enable non-file clipboard synchronization through the installed RustDesk CLI."""
import argparse
import datetime
import importlib.util
import json
import os
from pathlib import Path
import sys

spec = importlib.util.spec_from_file_location(
    'rustdesk_policy', Path(__file__).with_name('configure-rustdesk-password-access.py'))
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)

CLIPBOARD = {
    'enable-clipboard': 'Y',
    'disable-clipboard': 'N',
    'one-way-clipboard-redirection': 'N',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--expected-id', required=True)
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error('administrator privileges are required')
    if policy.cli('--get-id').replace(' ', '') != args.expected_id.replace(' ', ''):
        parser.error('CLI identity differs from the intended desktop')
    protected = {k: policy.cli('--option', k) for k in [
        *policy.DISABLED, 'approve-mode', 'verification-method',
        'allow-only-conn-window-open', 'custom-rendezvous-server', 'relay-server', 'key']}
    if any(protected[k] != 'N' for k in policy.DISABLED):
        parser.error('expected existing disabled permissions; no changes applied')
    before = {k: policy.cli('--option', k) for k in CLIPBOARD}
    directory = Path('/var/db/t3-rustdesk-policy' if sys.platform == 'darwin'
                     else '/var/lib/t3-rustdesk-policy')
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    with open(directory / (stamp + '-clipboard.json'), 'x',
              opener=lambda p, f: os.open(p, f, 0o600)) as stream:
        json.dump(before, stream, indent=2)
    try:
        for key, value in CLIPBOARD.items():
            policy.cli('--option', key, value)
            if policy.cli('--option', key) != value:
                raise RuntimeError('Clipboard setting was not retained')
        if any(policy.cli('--option', k) != v for k, v in protected.items()):
            raise RuntimeError('A protected setting changed unexpectedly')
    except Exception:
        for key, value in before.items():
            policy.cli('--option', key, value)
        raise
    print('Clipboard synchronization enabled; authentication and file-transfer policy unchanged')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, policy.subprocess.TimeoutExpired) as error:
        raise SystemExit(type(error).__name__ + ': clipboard update failed; details suppressed') from None
