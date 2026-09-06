#!/usr/bin/env python3
"""Verify an unpublished engine/consumer pair using the committed Git pin.

Only child processes receive the local Git transport mapping. No dependency
override or repository/global Git configuration is written. Hosted dependencies
still require network access. Run again after changing the committed engine pin.
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile


def run(command, cwd, env=None):
    subprocess.run(command, cwd=cwd, env=env, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', required=True, type=Path)
    args = parser.parse_args()
    adapter = Path(__file__).resolve().parents[1]
    repository = adapter.parents[1]
    manifest = (adapter / 'pubspec.yaml').read_text()
    pin = re.search(r'^      ref: ([a-f0-9]{40})$', manifest, re.MULTILINE)
    url = re.search(r'^      url: (\S+)$', manifest, re.MULTILINE)
    if pin is None or url is None:
        raise ValueError('Expected a full Git pin for whitelabel in pubspec.yaml')
    engine = args.engine.resolve(strict=True)
    run(['git', 'cat-file', '-e', f'{pin[1]}^{{commit}}'], engine)
    print(f'Verifying committed engine {pin[1]} with consumer {repository}', flush=True)
    lock = (adapter / 'pubspec.lock').read_bytes()
    with tempfile.TemporaryDirectory(prefix='wallet-branding-pub-') as cache:
        env = os.environ.copy()
        count = int(env.get('GIT_CONFIG_COUNT', '0'))
        env[f'GIT_CONFIG_KEY_{count}'] = f'url.{engine.as_uri()}.insteadOf'
        env[f'GIT_CONFIG_VALUE_{count}'] = url[1]
        env['GIT_CONFIG_COUNT'] = str(count + 1)
        env['PUB_CACHE'] = cache
        if (adapter / 'pubspec_overrides.yaml').exists():
            raise ValueError('Remove local pubspec_overrides.yaml before verifying the committed pair')
        run(['dart', 'pub', 'get', '--enforce-lockfile'], adapter, env)
        run(['dart', 'format', '--output=none', '--set-exit-if-changed', '.'], adapter, env)
        run(['dart', 'analyze', '--fatal-infos'], adapter, env)
        run(['dart', 'test'], adapter, env)
        run(['python3', 'tool/verify_parity.py', '--repo', str(repository)], adapter, env)
        if (adapter / 'pubspec.lock').read_bytes() != lock:
            raise RuntimeError('Verification changed the committed dependency lock')
    print('Pinned pair verified; no dependency override was used.', flush=True)


if __name__ == '__main__':
    main()
