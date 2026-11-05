#!/usr/bin/env python3
"""One-time, explicit launchd identity migration; no application data is moved."""
import argparse
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile

NEW = 'md.lifeos.LanDesk'
OLD = ('com.carriez.LanDesk', 'dev.quanru.LocalDesk')
APP = '/Applications/LanDesk.app/Contents/MacOS/'


def path_for(label, kind):
    directory = 'LaunchDaemons' if kind == 'service' else 'LaunchAgents'
    return Path('/Library') / directory / f'{label}_{kind}.plist'


def read_job(path, label, kind):
    if path.is_symlink():
        raise RuntimeError(f'Refusing symlink: {path}')
    body = plistlib.loads(path.read_bytes())
    expected = ['/bin/sh', '-c', APP + 'service'] if kind == 'service' else [APP + 'LanDesk', '--server']
    if body.get('Label') != f'{label}_{kind}' or body.get('ProgramArguments') != expected:
        raise RuntimeError(f'Unexpected job identity or executable: {path}')
    if body.get('AssociatedBundleIdentifiers') != 'dev.quanru.localdesk':
        raise RuntimeError(f'Unexpected app identity: {path}')
    return body


def write_job(path, body):
    fd, temporary = tempfile.mkstemp(prefix=path.name + '.', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            plistlib.dump(body, stream)
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def domain(kind, uid):
    return 'system' if kind == 'service' else f'gui/{uid}'


def run(*args, check=True):
    return subprocess.run(['/bin/launchctl', *args], check=check, capture_output=True, text=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--uid', required=True, type=int)
    parser.add_argument('--apply', action='store_true', help='requires administrator privileges')
    args = parser.parse_args()
    if args.uid < 500:
        raise RuntimeError('Expected a logged-in user UID')
    jobs = {}
    sources = {}
    for label in OLD:
        for kind in ('service', 'server'):
            path = path_for(label, kind)
            if path.exists():
                jobs[(label, kind)] = read_job(path, label, kind)
                sources.setdefault(kind, jobs[(label, kind)])
    if set(sources) != {'service', 'server'}:
        raise RuntimeError('Both existing LanDesk service and agent are required')
    existing = {}
    for kind in sources:
        path = path_for(NEW, kind)
        if path.exists():
            existing[kind] = read_job(path, NEW, kind)
    print('Validated migration:', ', '.join(f'{label}_{kind}' for label, kind in jobs), '->', NEW, flush=True)
    if not args.apply:
        return
    if os.geteuid() != 0:
        raise RuntimeError('--apply requires administrator privileges')
    # Remember which jobs were loaded so a failed bootstrap can restore that state.
    loaded = [(label, kind) for label, kind in jobs
              if run('print', f'{domain(kind, args.uid)}/{label}_{kind}', check=False).returncode == 0]
    loaded += [(NEW, kind) for kind in existing
               if run('print', f'{domain(kind, args.uid)}/{NEW}_{kind}', check=False).returncode == 0]
    written = []
    try:
        for kind, source in sources.items():
            if kind in existing:
                continue
            body = dict(source, Label=f'{NEW}_{kind}')
            path = path_for(NEW, kind)
            write_job(path, body)
            written.append(path)
        for label, kind in loaded:
            run('bootout', f'{domain(kind, args.uid)}/{label}_{kind}')
        for kind in ('service', 'server'):
            run('bootstrap', domain(kind, args.uid), str(path_for(NEW, kind)))
            run('print', f'{domain(kind, args.uid)}/{NEW}_{kind}')
    except Exception:
        for kind in ('server', 'service'):
            run('bootout', f'{domain(kind, args.uid)}/{NEW}_{kind}', check=False)
        for path in written:
            path.unlink(missing_ok=True)
        for label, kind in loaded:
            if run('print', f'{domain(kind, args.uid)}/{label}_{kind}', check=False).returncode != 0:
                run('bootstrap', domain(kind, args.uid), str(path_for(label, kind)))
        raise
    for label, kind in jobs:
        path_for(label, kind).unlink()
    print('Migrated both launchd jobs; removed verified old jobs; application data unchanged.', flush=True)


if __name__ == '__main__':
    main()
