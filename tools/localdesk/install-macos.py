#!/usr/bin/env python3
"""Install a verified same-identity build without changing app data or TCC grants."""
import argparse
import os
from pathlib import Path
import plistlib
import shutil
import signal
import subprocess
import tempfile


def main():
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('--destination', type=Path, default=Path('/Applications/LocalDesk.app'))
    parser.add_argument('--identity', default=os.environ.get('LANDESK_CODESIGN_IDENTITY'))
    parser.add_argument('--migrate-adhoc', action='store_true')
    args = parser.parse_args()
    if not args.identity:
        result = subprocess.run(['git', '-C', str(root), 'config', '--get', 'landesk.codesignIdentity'], text=True, capture_output=True)
        args.identity = result.stdout.strip()
    if not args.identity or args.identity == '-':
        parser.error('Configure landesk.codesignIdentity with a fixed certificate')
    dest = args.destination.resolve()
    if dest.suffix != '.app' or args.app.resolve() == dest:
        parser.error('Use a separate built .app as the source')
    with (args.app / 'Contents/Info.plist').open('rb') as f:
        info = plistlib.load(f)
    if info.get('CFBundleIdentifier') != 'dev.quanru.localdesk':
        parser.error('Unexpected source bundle identity')
    old_exe = info['CFBundleExecutable']
    if dest.exists():
        with (dest / 'Contents/Info.plist').open('rb') as f:
            old = plistlib.load(f)
        if old.get('CFBundleIdentifier') != info['CFBundleIdentifier']:
            parser.error('Destination bundle identity differs')
        old_exe = old['CFBundleExecutable']
    with tempfile.TemporaryDirectory(prefix='landesk-install-') as tmp:
        stage = Path(tmp) / dest.name
        shutil.copytree(args.app, stage, symlinks=True)
        source_exe = info['CFBundleExecutable']
        if old_exe != source_exe:
            (stage / 'Contents/MacOS' / source_exe).rename(stage / 'Contents/MacOS' / old_exe)
            info['CFBundleExecutable'] = old_exe
            with (stage / 'Contents/Info.plist').open('wb') as f:
                plistlib.dump(info, f)
        sign = ['python3', str(root / 'tools/localdesk/sign-macos.py'), str(stage), '--identity', args.identity]
        if dest.exists():
            sign += ['--previous-app', str(dest)]
        if args.migrate_adhoc:
            sign.append('--migrate-adhoc')
        subprocess.run(sign, check=True)
        # Only stop this user's processes from the exact installed executable.
        # The root launcher is not the user-session capture process.
        executable = str(dest / 'Contents/MacOS' / old_exe)
        processes = subprocess.check_output(['ps', '-axo', 'pid=,uid=,args='], text=True)
        for line in processes.splitlines():
            parts = line.strip().split(None, 2)
            if len(parts) == 3 and int(parts[1]) == os.getuid() and (parts[2] == executable or parts[2].startswith(executable + ' ')):
                try:
                    os.kill(int(parts[0]), signal.SIGTERM)
                except ProcessLookupError:
                    pass
        subprocess.run(['rsync', '-a', '--delete', '--force', str(stage) + '/', str(dest) + '/'], check=True)
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(dest)], check=True)
    subprocess.run(['open', str(dest)], check=True)
    subprocess.Popen([executable, '--server'], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    print('Installed verified app; GUI and user-session server restarted. TCC settings unchanged.')


if __name__ == '__main__':
    main()
