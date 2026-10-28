#!/usr/bin/env python3
"""Sign a local development app consistently; never fall back to ad-hoc signing."""
import argparse
import os
from pathlib import Path
import subprocess


def run(*args):
    return subprocess.run(args, check=True, text=True, capture_output=True)


def requirement(app):
    output = run('codesign', '-d', '-r-', str(app))
    for line in (output.stdout + output.stderr).splitlines():
        if line.startswith('designated => '):
            return line.removeprefix('designated => ')
    raise RuntimeError('App has no certificate-backed designated requirement')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('--identity', default=os.environ.get('LANDESK_CODESIGN_IDENTITY'))
    parser.add_argument('--previous-app', type=Path)
    parser.add_argument('--migrate-adhoc', action='store_true')
    args = parser.parse_args()
    if not args.identity or args.identity == '-':
        parser.error('Set LANDESK_CODESIGN_IDENTITY to a fixed certificate; ad-hoc is not supported')
    previous = None
    if args.previous_app:
        details = run('codesign', '-dv', str(args.previous_app)).stderr
        if 'Signature=adhoc' in details:
            if not args.migrate_adhoc:
                parser.error('Ad-hoc migration must be explicit; one-time system reauthorization may be needed')
        else:
            previous = requirement(args.previous_app)
    app = args.app.resolve()
    if not (app / 'Contents/Info.plist').is_file():
        parser.error('Expected a macOS .app bundle')
    # Sign nested code from the inside out, preserving framework symlinks.
    frameworks = list((app / 'Contents/Frameworks').glob('*.framework'))
    code = list((app / 'Contents/Frameworks').glob('*.dylib'))
    service = app / 'Contents/MacOS/service'
    if service.exists():
        code.append(service)
    for path in code + sorted(frameworks, key=lambda p: len(p.parts), reverse=True):
        run('codesign', '--force', '--sign', args.identity, '--options', 'runtime', str(path))
    entitlements = Path(__file__).resolve().parents[2] / 'flutter/macos/Runner/UnsignedRelease.entitlements'
    run('codesign', '--force', '--sign', args.identity, '--options', 'runtime',
        '--entitlements', str(entitlements), str(app))
    run('codesign', '--verify', '--deep', '--strict', str(app))
    current = requirement(app)
    if previous:
        run('codesign', '--verify', '-R', '=' + previous, str(app))
    print(current)
    print('Verified certificate-backed app signature' + (' and previous identity compatibility' if previous else ''))


if __name__ == '__main__':
    main()
