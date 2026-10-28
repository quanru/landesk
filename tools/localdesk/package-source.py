#!/usr/bin/env python3
"""Export tracked sources and pinned submodules, never local credentials/builds."""
import argparse
import io
import json
import subprocess
import tarfile
from pathlib import Path


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])


def export(repo, revision, prefix, output, pins):
    commit = git(repo, 'rev-parse', revision + '^{commit}').decode().strip()
    pins[prefix] = commit
    data = git(repo, 'archive', '--format=tar', commit)
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        for member in archive:
            member.name = prefix + '/' + member.name
            output.addfile(member, archive.extractfile(member) if member.isfile() else None)
    for entry in git(repo, 'ls-tree', '-rz', commit).split(b'\0'):
        if not entry:
            continue
        metadata, path = entry.split(b'\t', 1)
        mode, kind, sha = metadata.decode().split()
        if mode == '160000':
            relative = path.decode()
            export(repo / relative, sha, prefix + '/' + relative, output, pins)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('revision')
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    pins = {}
    # Exclusive creation prevents silently replacing a published artifact.
    with args.output.open('xb') as target:
        with tarfile.open(fileobj=target, mode='w:gz') as archive:
            export(repo, args.revision, 'landesk', archive, pins)
            manifest = json.dumps(pins, indent=2).encode() + b'\n'
            info = tarfile.TarInfo('landesk/SOURCE_REVISIONS.json')
            info.size = len(manifest)
            archive.addfile(info, io.BytesIO(manifest))
    print(json.dumps(pins, indent=2))


if __name__ == '__main__':
    main()
