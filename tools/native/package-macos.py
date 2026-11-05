#!/usr/bin/env python3
"""Embed local dylib dependencies and sign a development macOS bundle."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('app', type=Path)
    parser.add_argument('--identity', required=True)
    parser.add_argument('--service', required=True, type=Path)
    args = parser.parse_args()
    app = args.app.resolve()
    frameworks = app / 'Contents/Frameworks'
    frameworks.mkdir(exist_ok=True)
    shutil.copy2(args.service, app / 'Contents/MacOS/service')
    binaries = []
    for path in app.rglob('*'):
        if path.is_file() and not path.is_symlink():
            if 'Mach-O' in run('file', '-b', str(path)):
                binaries.append(path)
    pending = list(binaries)
    while pending:
        binary = pending.pop()
        lines = run('otool', '-L', str(binary)).splitlines()[1:]
        for line in lines:
            dependency = line.strip().split(' (')[0]
            target = None
            if dependency.startswith('/opt/homebrew/'):
                target = frameworks / Path(dependency).name
                if not target.exists():
                    shutil.copy2(Path(dependency).resolve(), target)
                    pending.append(target)
                    binaries.append(target)
                    run('install_name_tool', '-id', '@rpath/' + target.name, str(target))
            elif '/target/' in dependency and dependency.endswith('/liblibrustdesk.dylib'):
                target = frameworks / 'liblibrustdesk.dylib'
            if target and target != binary:
                replacement = '@loader_path/' + os.path.relpath(target, binary.parent)
                run('install_name_tool', '-change', dependency, replacement, str(binary))
    entitlements = app.parent / 'landesk-development.entitlements'
    entitlements.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>com.apple.security.cs.allow-jit</key><true/>
<key>com.apple.security.cs.disable-library-validation</key><true/>
<key>com.apple.security.network.client</key><true/>
<key>com.apple.security.network.server</key><true/>
<key>com.apple.security.device.audio-input</key><true/>
</dict></plist>''')
    for path in sorted(binaries, key=lambda p: len(p.parts), reverse=True):
        run('codesign', '--force', '--sign', args.identity, str(path))
    for path in sorted(app.rglob('*.framework'), key=lambda p: len(p.parts), reverse=True):
        run('codesign', '--force', '--sign', args.identity, str(path))
    run('codesign', '--force', '--sign', args.identity, '--entitlements', str(entitlements), str(app))
    run('codesign', '--verify', '--deep', '--strict', str(app))
    print(f'Verified development signature: {app}')


if __name__ == '__main__':
    main()
