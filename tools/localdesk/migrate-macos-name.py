#!/usr/bin/env python3
"""Prepare a signed LanDesk bundle, then migrate legacy launch jobs with sudo."""
import argparse
import os
from pathlib import Path
import plistlib
import shutil
import signal
import subprocess
import tempfile
import time

OLD = Path('/Applications/LocalDesk.app')
NEW = Path('/Applications/LanDesk.app')
JOBS = (
    Path('/Library/LaunchAgents/dev.quanru.LocalDesk_server.plist'),
    Path('/Library/LaunchDaemons/dev.quanru.LocalDesk_service.plist'),
)


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def renamed(value):
    if isinstance(value, str):
        return value.replace(str(OLD) + '/Contents/MacOS/LocalDesk',
                             str(NEW) + '/Contents/MacOS/LanDesk').replace(str(OLD), str(NEW))
    if isinstance(value, list):
        return [renamed(item) for item in value]
    if isinstance(value, dict):
        return {key: renamed(item) for key, item in value.items()}
    return value


def verify(app):
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    if info['CFBundleIdentifier'] != 'dev.quanru.localdesk':
        raise RuntimeError('Unexpected bundle identity')
    run('codesign', '--verify', '--deep', '--strict', str(app))
    return info


def prepare():
    if os.geteuid() == 0:
        raise RuntimeError('Prepare as the current user, not root, to access the signing keychain')
    if NEW.exists():
        raise RuntimeError('LanDesk.app already exists; refusing to overwrite it')
    info = verify(OLD)
    root = Path(__file__).resolve().parents[2]
    identity = subprocess.check_output(
        ['git', '-C', str(root), 'config', '--get', 'landesk.codesignIdentity'], text=True).strip()
    stage = Path(tempfile.mkdtemp(prefix='landesk-name-')) / NEW.name
    shutil.copytree(OLD, stage, symlinks=True)
    (stage / 'Contents/MacOS' / info['CFBundleExecutable']).rename(stage / 'Contents/MacOS/LanDesk')
    info.update(CFBundleExecutable='LanDesk', CFBundleName='LanDesk', CFBundleDisplayName='LanDesk')
    (stage / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
    run('python3', str(root / 'tools/localdesk/sign-macos.py'), str(stage),
        '--identity', identity, '--previous-app', str(OLD))
    for path in JOBS:
        value = renamed(plistlib.loads(path.read_bytes()))
        if str(OLD) in str(value):
            raise RuntimeError(f'Unmigrated path in {path}')
        print(f'Validated launch job: {path.name}')
    print(f'Prepared: {stage}')


def activate(stage):
    if os.geteuid() != 0:
        raise RuntimeError('Activation requires sudo to update /Library launch jobs')
    uid = int(os.environ['SUDO_UID'])
    if uid == 0 or NEW.exists() or stage.name != NEW.name:
        raise RuntimeError('Expected an existing user install and a new LanDesk destination')
    verify(OLD)
    info = verify(stage)
    if info['CFBundleExecutable'] != 'LanDesk' or info['CFBundleDisplayName'] != 'LanDesk':
        raise RuntimeError('Stage has not been prepared')
    result = subprocess.run(['codesign', '-d', '-r-', str(OLD)],
                            check=True, capture_output=True, text=True)
    requirement = result.stdout + result.stderr
    req = next(line.removeprefix('designated => ') for line in requirement.splitlines()
               if line.startswith('designated => '))
    run('codesign', '--verify', '-R', '=' + req, str(stage))
    originals = {path: path.read_bytes() for path in JOBS}
    domains = {JOBS[0]: f'gui/{uid}', JOBS[1]: 'system'}
    loaded = []
    for path in JOBS:
        label = plistlib.loads(originals[path])['Label']
        state = subprocess.run(['launchctl', 'print', domains[path] + '/' + label],
                               capture_output=True)
        if state.returncode == 0:
            loaded.append(path)
    shutil.copytree(stage, NEW, symlinks=True)
    for directory, subdirs, files in os.walk(NEW):
        for entry in [Path(directory)] + [Path(directory) / name for name in subdirs + files]:
            os.chown(entry, uid, OLD.stat().st_gid, follow_symlinks=False)
    try:
        for path in loaded:
            run('launchctl', 'bootout', domains[path], str(path))
        processes = subprocess.check_output(['ps', '-axo', 'pid=,uid=,args='], text=True)
        for line in processes.splitlines():
            parts = line.strip().split(None, 2)
            if len(parts) == 3 and int(parts[1]) == uid and parts[2].startswith(str(OLD) + '/Contents/MacOS/'):
                try:
                    os.kill(int(parts[0]), signal.SIGTERM)
                except ProcessLookupError:
                    pass
        time.sleep(1)
        for path, data in originals.items():
            path.write_bytes(plistlib.dumps(renamed(plistlib.loads(data))))
        for path in loaded:
            run('launchctl', 'bootstrap', domains[path], str(path))
        verify(NEW)
    except Exception:
        for path in loaded:
            subprocess.run(['launchctl', 'bootout', domains[path], str(path)], capture_output=True)
        for path, data in originals.items():
            path.write_bytes(data)
        for path in loaded:
            run('launchctl', 'bootstrap', domains[path], str(path))
        shutil.rmtree(NEW)
        raise
    # Only remove the old installation after the signed replacement and launch jobs succeed.
    shutil.rmtree(OLD)
    shutil.rmtree(stage)
    print('Migrated to /Applications/LanDesk.app. Launch job identities and app data preserved.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', type=Path, help='Activate a prepared bundle (requires sudo)')
    args = parser.parse_args()
    activate(args.apply.resolve()) if args.apply else prepare()
