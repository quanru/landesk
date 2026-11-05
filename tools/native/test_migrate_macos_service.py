import importlib.util
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('migration', Path(__file__).with_name('migrate-macos-service.py'))
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


class MigrationTests(unittest.TestCase):
    def scenario(self, fail=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def path_for(label, kind):
                return root / f'{label}_{kind}.plist'
            loaded = set()
            original = {}
            for label in (migration.OLD[0], migration.NEW):
                for kind in ('service', 'server'):
                    body = {'Label': f'{label}_{kind}',
                            'AssociatedBundleIdentifiers': 'dev.quanru.localdesk',
                            'ProgramArguments': (['/bin/sh', '-c', migration.APP + 'service']
                                                 if kind == 'service' else [migration.APP + 'LanDesk', '--server'])}
                    data = plistlib.dumps(body)
                    path_for(label, kind).write_bytes(data)
                    original[(label, kind)] = data
                    loaded.add(f'{migration.domain(kind, 501)}/{label}_{kind}')
            initial = set(loaded)
            failed = False
            def run(action, target, *args, check=True):
                nonlocal failed
                if action == 'print':
                    return subprocess.CompletedProcess([], 0 if target in loaded else 113)
                if action == 'bootout':
                    loaded.discard(target)
                elif action == 'bootstrap':
                    label = plistlib.loads(Path(args[0]).read_bytes())['Label']
                    if fail and not failed and label == migration.NEW + '_server':
                        failed = True
                        raise subprocess.CalledProcessError(5, ['launchctl'])
                    loaded.add(target + '/' + label)
                return subprocess.CompletedProcess([], 0)
            with patch.object(migration, 'path_for', path_for), patch.object(migration, 'run', run), \
                    patch.object(migration.os, 'geteuid', return_value=0), \
                    patch('sys.argv', ['migration', '--uid', '501', '--apply']):
                if fail:
                    with self.assertRaises(subprocess.CalledProcessError):
                        migration.main()
                    self.assertEqual(loaded, initial)
                    for key, data in original.items():
                        self.assertEqual(path_for(*key).read_bytes(), data)
                else:
                    migration.main()
                    self.assertEqual(loaded, {f'{migration.domain(k, 501)}/{migration.NEW}_{k}'
                                              for k in ('service', 'server')})
                    for kind in ('service', 'server'):
                        self.assertFalse(path_for(migration.OLD[0], kind).exists())
                        self.assertEqual(path_for(migration.NEW, kind).read_bytes(), original[(migration.NEW, kind)])

    def test_existing_new_jobs_replace_old_jobs_without_overwriting_plists(self):
        self.scenario()

    def test_failed_bootstrap_restores_preexisting_jobs_and_files(self):
        self.scenario(fail=True)


if __name__ == '__main__':
    unittest.main()
