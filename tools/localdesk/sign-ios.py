"""Sign the already-built iPad app using an explicit local identity and profile."""
import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--identity', required=True)
parser.add_argument('--profile', required=True, type=Path)
args = parser.parse_args()
app = Path(__file__).resolve().parents[2] / 'flutter/build/ios/iphoneos/Runner.app'
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'dev.quanru.localdesk'
profile = plistlib.loads(subprocess.check_output(
    ['security', 'cms', '-D', '-i', str(args.profile)], stderr=subprocess.DEVNULL))
entitlements = dict(profile['Entitlements'])
identifier = profile['TeamIdentifier'][0] + '.' + info['CFBundleIdentifier']
entitlements['application-identifier'] = identifier
entitlements['keychain-access-groups'] = [identifier]
shutil.copyfile(args.profile, app / 'embedded.mobileprovision')
with tempfile.NamedTemporaryFile(suffix='.plist') as output:
    output.write(plistlib.dumps(entitlements))
    output.flush()
    for binary in sorted(list(app.rglob('*.framework')) + list(app.rglob('*.dylib')),
                         key=lambda path: len(path.parts), reverse=True):
        subprocess.run(['codesign', '--force', '--sign', args.identity, str(binary)], check=True)
    subprocess.run(['codesign', '--force', '--sign', args.identity,
                    '--entitlements', output.name, str(app)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
