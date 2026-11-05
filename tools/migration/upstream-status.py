#!/usr/bin/env python3
"""Read-only ancestry and upstream-change report; never fetch, merge or publish."""
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()


def ancestor(older, newer):
    return subprocess.run(['git', 'merge-base', '--is-ancestor', older, newer],
                          cwd=ROOT, check=False).returncode == 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', default='rustdesk/master')
    args = parser.parse_args()
    baseline = json.loads((ROOT / 'tools/migration/native-baseline.json').read_text())
    base = baseline['upstream_app']
    target = git('rev-parse', '--verify', args.target + '^{commit}')
    if not ancestor(base, 'HEAD'):
        raise SystemExit('ERROR: recorded upstream baseline is not an ancestor of HEAD')
    if not ancestor(base, target):
        raise SystemExit('ERROR: target does not descend from the recorded upstream baseline')
    common = git('ls-tree', 'HEAD', 'libs/hbb_common').split()[2]
    if common != baseline['upstream_common']:
        raise SystemExit('ERROR: hbb_common gitlink differs from recorded baseline')
    incoming = set(filter(None, git('diff', '--name-only', base, target).splitlines()))
    local = set(filter(None, git('diff', '--name-only', base, 'HEAD').splitlines()))
    report = {
        'head': git('rev-parse', 'HEAD'),
        'baseline': base,
        'target': target,
        'incoming_commits': int(git('rev-list', '--count', base + '..' + target)),
        'working_tree_clean': not bool(git('status', '--porcelain')),
        'common_baseline': common,
        'common_target': git('ls-tree', target, 'libs/hbb_common').split()[2],
        'local_delta_files': sorted(local),
        'incoming_files': sorted(incoming),
        'overlapping_files': sorted(local & incoming),
        'note': 'File overlap is a review aid, not a semantic-conflict or test guarantee.',
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
