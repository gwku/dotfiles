#!/usr/bin/env python3
"""Refresh the local Forgejo CLI login from restricted Infisical; never print secrets."""
import json
import os
from pathlib import Path
import re
import subprocess
import urllib.error
import urllib.request

HOST = 'https://git.marketingconcurrent.nl'
PROJECT = 'fd4ac2d8-c83a-41ba-955f-6b4556f4f701'
SECRET = 'FORGEJO_AGENT_TOKEN'
CLI = '/opt/homebrew/bin/fj'

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def main():
    result = subprocess.run([
        'infisical', 'secrets', 'get', SECRET, '--plain', '--projectId', PROJECT,
        '--env', 'prod', '--path', '/', '--include-imports=false',
        '--domain', 'https://infisical.marketingconcurrent.nl/api', '--silent',
    ], capture_output=True, text=True)
    token = result.stdout.strip()
    if result.returncode or not re.fullmatch(r'[0-9a-f]{40}', token):
        raise SystemExit('Forgejo agent credential unavailable. Check the Infisical CLI login and restricted project access; no secret output displayed.')
    request = urllib.request.Request(HOST + '/api/v1/user', headers={'Authorization': 'token ' + token})
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=30) as response:
            user = json.load(response)
    except urllib.error.HTTPError as error:
        raise SystemExit('Forgejo credential validation failed: HTTP ' + str(error.code)) from None
    if user.get('id') != 1 or user.get('login', '').lower() != 'gwku':
        raise SystemExit('Unexpected Forgejo identity; local CLI login was not changed.')
    result = subprocess.run([CLI, '--host', HOST, 'auth', 'add-token'], input=token + '\n', capture_output=True, text=True)
    if result.returncode:
        raise SystemExit('Forgejo CLI login failed; sensitive CLI output suppressed.')
    paths = [Path.home() / 'Library/Application Support' / (org + '.forgejo-cli') / 'keys.json' for org in ['forgejo-cli', 'Cyborus']]
    found = False
    for path in paths:
        if path.is_file():
            os.chmod(path.parent, 0o700)
            os.chmod(path, 0o600)
            found = True
    if not found:
        raise SystemExit('CLI returned success but its expected private credential file was not found; check the installed CLI storage format.')
    print('Forgejo CLI authenticated as gwku. Infisical remains authoritative; local credential cache restricted to this user.')

if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception as error:
        raise SystemExit('Forgejo login failed: ' + type(error).__name__ + '; sensitive details suppressed.') from None
