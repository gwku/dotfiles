#!/usr/bin/env python3
"""Hold a Linux sleep inhibitor only while an external power supply is online."""
import os
from pathlib import Path
import signal
import subprocess
import time


def on_ac(root=Path('/sys/class/power_supply')):
    for supply in root.iterdir():
        try:
            kind = (supply / 'type').read_text().strip()
            if (kind in {'Mains', 'Wireless'} or kind.startswith('USB')) and (supply / 'online').read_text().strip() == '1':
                return True
        except (FileNotFoundError, OSError):
            continue
    return False


def main():
    stopping = False
    child = None

    def stop(_signum, _frame):
        nonlocal stopping
        stopping = True

    def release():
        nonlocal child
        if child and child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
        child = None

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        while not stopping:
            if on_ac():
                if child is None or child.poll() is not None:
                    child = subprocess.Popen([
                        '/usr/bin/systemd-inhibit', '--what=idle:sleep', '--mode=block',
                        '--who=AC remote access', '--why=Keep awake while plugged in',
                        '/usr/bin/sleep', 'infinity',
                    ], start_new_session=True)
            else:
                release()
            time.sleep(3)
    finally:
        release()


if __name__ == '__main__':
    main()
