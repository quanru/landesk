#!/usr/bin/env python3
"""Validate and Developer ID sign a CI-built LanDesk bundle before notarization."""
import argparse
import plistlib
import subprocess
from pathlib import Path


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('app', type=Path)
    parser.add_argument('--identity', required=True)
    args = parser.parse_args()
    app = args.app.resolve()
    info_path = app / 'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    if info['CFBundleIdentifier'] != 'dev.quanru.localdesk' or info['CFBundleExecutable'] != 'LanDesk':
        raise ValueError('Unexpected application identity')
    # The native core in landesk-macos.yml is built with this deployment target.
    info['LSMinimumSystemVersion'] = '12.3'
    info_path.write_bytes(plistlib.dumps(info))
    binaries = [p for p in app.rglob('*') if p.is_file() and not p.is_symlink()
                and 'Mach-O' in run('file', '-b', str(p))]
    for binary in binaries:
        for line in run('otool', '-L', str(binary)).splitlines()[1:]:
            dependency = line.strip().split(' (')[0]
            if not dependency.startswith(('@', '/usr/lib/', '/System/Library/')):
                raise ValueError(f'Non-portable dependency in {binary.name}: {dependency}')
    if not (app / 'Contents/MacOS/service').is_file():
        raise ValueError('Missing native service')
    sign = ['codesign', '--force', '--sign', args.identity, '--options', 'runtime', '--timestamp']
    for binary in sorted(binaries, key=lambda p: len(p.parts), reverse=True):
        run(*sign, str(binary))
    for framework in sorted(app.rglob('*.framework'), key=lambda p: len(p.parts), reverse=True):
        if not framework.is_symlink():
            run(*sign, str(framework))
    entitlements = Path(__file__).resolve().parents[2] / 'flutter/macos/Runner/Release.entitlements'
    run(*sign, '--entitlements', str(entitlements), str(app))
    run('codesign', '--verify', '--deep', '--strict', str(app))
    print(f"Signed {info['CFBundleShortVersionString']} ({info['CFBundleVersion']}): {app}")


if __name__ == '__main__':
    main()
