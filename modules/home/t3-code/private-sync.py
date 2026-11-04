#!/usr/bin/env python3
"""One-authority portable preference replication; private state, no Git writes."""
import argparse
import base64
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

SERVER = {'favorites', 'storageCleanup', 'defaultAutoPull', 'defaultModelSelection',
          'autoResumeLimitedThreads', 'defaultThreadEnvMode', 'newWorktreesStartFromOrigin',
          'enableProviderUpdateChecks'}
CLIENT = set('''appearanceContrast browserAutoShowFloatingPreview browserDefaultAppearance
 browserDefaultViewport browserDefaultZoomFactor browserLinkTarget browserRecordingFrameRate
 browserRecordingShowKeyPresses browserRecordingShowMousePresses chatWidth composerCollapseOnScroll
 composerRichTextEnabled confirmQuit confirmThreadArchive confirmThreadDelete confirmThreadUnpin
 contextWindowMeterEnabled diffColorScheme diffFilesCollapsed diffIgnoreWhitespace diffLayout
 environmentIdentificationMode favorites followUpBehavior fontFamilyCode fontFamilyComposer
 fontFamilySans fontFamilyTerminal fontSizeCode fontSizeInterface fontSizePrompt fontSizeTerminal
 fontSmoothing glassOpacity inAppNotificationsEnabled legacySidebarEnabled loadBalancingEnabled
 notificationMode panelAnimationDurationMs persistComposerContextStrip planModeEnabled proactivePanelsEnabled
 pullRequestLinksOpenInApp sendShortcut showSkillsInSlashMenu sidebarProjectGroupingMode
 sidebarProjectSortOrder sidebarThreadPreviewCount sidebarThreadSortOrder sidebarWorkingShelfEnabled
 snapShotAnimations snapShotEnabled snapShotFlash snapShotIncludeAccessibility snapShotPlaySound
 snapShotShortcut snapShotSound timestampFormat wordWrap'''.split())
STOCK_DRIVERS = {'codex', 'claudeAgent', 'opencode', 'gemini', 'cursor', 'copilot'}
ROOT = Path.home() / '.t3/userdata'
STATE = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state')) / 't3-portable-sync'


def read(path, fallback=None):
    return json.loads(path.read_text()) if path.exists() else fallback


def safe(value):
    if value is None or isinstance(value, (bool, int, float)):
        return True
    if isinstance(value, str):
        return len(value) <= 160 and not any(x in value for x in ['://', '\n', '\r', '\x00', '\\']) and not value.startswith(('/', '~/', 'sk-', 'eyJ'))
    if isinstance(value, list):
        return len(value) <= 200 and all(safe(x) for x in value)
    if isinstance(value, dict):
        return len(value) <= 200 and all(isinstance(k, str) and safe(v) for k, v in value.items())
    return False


def model(value):
    if not isinstance(value, dict) or set(value) - {'provider', 'instanceId', 'model', 'options'}:
        return False
    if value.get('provider', value.get('instanceId')) not in STOCK_DRIVERS:
        return False
    if not isinstance(value.get('model'), str) or not safe(value['model']):
        return False
    options = value.get('options', [])
    if not isinstance(options, list):
        return False
    for option in options:
        if not isinstance(option, dict) or set(option) != {'id', 'value'} or option['id'] not in {'reasoningEffort', 'serviceTier', 'thinking', 'contextWindow'} or not safe(option['value']):
            return False
    return True


def validate(name, value):
    if not safe(value):
        return False
    if name == 'bindings':
        return isinstance(value, list) and all(isinstance(b, dict) and set(b) <= {'key', 'command', 'when'} and isinstance(b.get('key'), str) and isinstance(b.get('command'), str) and re.fullmatch(r'[A-Za-z][A-Za-z0-9_.-]*', b['command']) for b in value)
    if name in {'server:favorites', 'client:favorites'}:
        return isinstance(value, list) and all(model(v) for v in value)
    if name == 'server:defaultModelSelection':
        return value is None or model(value)
    if name == 'server:backgroundActivity.profile':
        return value in {'balanced', 'performance', 'battery-saver'}
    if name == 'server:storageCleanup':
        return isinstance(value, dict) and set(value) <= {'worktreeSettledAfterDays', 'worktreeOnMerge', 'worktreeOnDelete', 'browserArtifactsAfterDays', 'logsAfterDays'} and all(isinstance(v, (int, bool)) for v in value.values())
    if name == 'server:sourceControlWritingStyle.mode':
        return value in {'repo_conventions', 'conventional_commits', 'custom'}
    if name == 'server:sourceControlWritingStyle.followChangeRequestTemplates':
        return isinstance(value, bool)
    group, key = name.split(':', 1)
    return (group == 'server' and key in SERVER) or (group == 'client' and key in CLIENT)


def snapshot(documents=None):
    values = {}
    documents = documents or {}
    for group, filename, keys in [('server', 'settings.json', SERVER), ('client', 'client-settings.json', CLIENT)]:
        document = documents[filename] if filename in documents else read(ROOT / filename, {})
        for key in keys:
            name = group + ':' + key
            if key in document and validate(name, document[key]):
                values[name] = document[key]
        if group == 'server':
            profile = document.get('backgroundActivity', {}).get('profile')
            if validate('server:backgroundActivity.profile', profile):
                values['server:backgroundActivity.profile'] = profile
            for key in ['mode', 'followChangeRequestTemplates']:
                name = 'server:sourceControlWritingStyle.' + key
                value = document.get('sourceControlWritingStyle', {}).get(key)
                if validate(name, value):
                    values[name] = value
    bindings = documents['keybindings.json'] if 'keybindings.json' in documents else read(ROOT / 'keybindings.json', [])
    if validate('bindings', bindings):
        values['bindings'] = bindings
    return values


def equivalent(name, left, right):
    if name == 'bindings' and isinstance(left, list) and isinstance(right, list):
        return sorted(json.dumps(x, sort_keys=True) for x in left) == sorted(json.dumps(x, sort_keys=True) for x in right)
    return left == right


MISSING = object()


def file_bytes(path):
    return path.read_bytes() if path.exists() else None


def atomic(path, value, backup=False, expected=MISSING):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if expected is not MISSING and file_bytes(path) != expected:
        return False
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        json.dump(value, stream, indent=2)
        stream.write('\n')
    try:
        temporary.chmod(0o600)
        if backup and path.exists():
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
            b = path.with_name(path.name + '.before-private-sync-' + stamp)
            b.write_bytes(expected if expected is not MISSING else path.read_bytes())
            b.chmod(0o600)
        # Best-effort compare-and-swap: GUI writes do not honor this process's
        # private lock, so compare the exact observed bytes immediately before
        # replacing. An intervening edit aborts this entire target file.
        if expected is not MISSING and file_bytes(path) != expected:
            return False
        temporary.replace(path)
        return True
    finally:
        temporary.unlink(missing_ok=True)


def target_file(name):
    if name == 'bindings':
        return 'keybindings.json'
    return 'settings.json' if name.startswith('server:') else 'client-settings.json'


def receive(payload):
    if not isinstance(payload, dict) or len(payload) > 150 or any(not validate(k, v) for k, v in payload.items()):
        raise ValueError('Rejected non-portable payload')
    receipt = read(STATE / 'receipt.json', {})
    observed = {name: file_bytes(ROOT / name) for name in ['settings.json', 'client-settings.json', 'keybindings.json']}
    documents = {name: json.loads(raw) if raw is not None else ([] if name == 'keybindings.json' else {}) for name, raw in observed.items()}
    current = snapshot(documents)
    accepted, receipt_updates, conflicts = {}, {}, []
    for name, desired in payload.items():
        if equivalent(name, current.get(name), desired):
            receipt_updates[name] = desired
        elif name in receipt and equivalent(name, current.get(name), receipt[name]):
            accepted[name] = desired
            receipt_updates[name] = desired
        else:
            conflicts.append(name)
    changed = []
    for filename in sorted({target_file(name) for name in receipt_updates}):
        names = [name for name in receipt_updates if target_file(name) == filename]
        edits = {name: accepted[name] for name in names if name in accepted}
        document = documents[filename]
        for name, value in edits.items():
            if name == 'bindings':
                document = value
                continue
            _group, key = name.split(':', 1)
            if '.' in key:
                parent, child = key.split('.', 1)
                document.setdefault(parent, {})[child] = value
            else:
                document[key] = value
        if edits:
            applied = atomic(ROOT / filename, document, backup=True, expected=observed[filename])
        else:
            applied = file_bytes(ROOT / filename) == observed[filename]
        if applied:
            if edits:
                changed.append(filename)
            for name in names:
                receipt[name] = receipt_updates[name]
        else:
            # Never advance receipts for keys in an unapplied file.
            conflicts.extend(names)
    atomic(STATE / 'receipt.json', receipt)
    if 'client-settings.json' in changed:
        atomic(STATE / 'client-reload-required.json', {'changedAt': datetime.datetime.now(datetime.timezone.utc).isoformat()})
    return {'changed': changed, 'conflicts': sorted(set(conflicts)), 'clientReloadRequired': (STATE / 'client-reload-required.json').exists()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--receive', action='store_true')
    parser.add_argument('--ack-client-reload', action='store_true')
    parser.add_argument('--config', type=Path, default=Path.home() / '.config/t3-private/peers.json')
    args = parser.parse_args()
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (STATE / 'lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        if args.ack_client_reload:
            (STATE / 'client-reload-required.json').unlink(missing_ok=True)
            print('Client reload reminder cleared')
            return
        if args.receive:
            raw = sys.stdin.read(1024 * 1024 + 1)
            if len(raw) > 1024 * 1024:
                raise ValueError('Oversized private payload')
            print(json.dumps(receive(json.loads(raw))))
            return
        config = read(args.config, {}).get('settingsSync', {})
        if not config.get('enabled') or not config.get('authority'):
            return
        payload = snapshot()
        atomic(STATE / 'payload.json', payload)
        source = Path(__file__).read_text()
        encoded = base64.b64encode(source.encode()).decode()
        program = 'exec(__import__("base64").b64decode("' + encoded + '"))'
        remote = 'python3 -c ' + shlex.quote(program) + ' --receive'
        statuses = []
        for peer in config.get('peers', []):
            alias = peer['sshAlias']
            if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.@-]*', alias):
                raise ValueError('Invalid private SSH alias')
            try:
                result = subprocess.run(['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', '-o', 'ForwardAgent=no', '-o', 'ControlMaster=auto', '-o', 'ControlPersist=120', '-o', 'ControlPath=' + str(STATE / 'ssh-%C'), alias, remote], input=json.dumps(payload), text=True, capture_output=True, timeout=25, check=True)
                statuses.append({'peer': alias, **json.loads(result.stdout)})
            except (subprocess.SubprocessError, ValueError):
                statuses.append({'peer': alias, 'offline': True})
        atomic(STATE / 'status.json', statuses)
        print('Private T3 preference sync: {} peer(s), {} conflict(s), {} offline'.format(len(statuses), sum(len(x.get('conflicts', [])) for x in statuses), sum(bool(x.get('offline')) for x in statuses)))


if __name__ == '__main__':
    main()
