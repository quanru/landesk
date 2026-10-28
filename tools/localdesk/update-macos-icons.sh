#!/bin/sh
# Refresh branding with the same certificate identity. Does not modify TCC grants.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
app_path=${1:-/Applications/LocalDesk.app}
framework="$app_path/Contents/Frameworks/App.framework"
assets="$framework/Versions/A/Resources/flutter_assets/assets"
[ -f "$app_path/Contents/Resources/AppIcon.icns" ]
[ -f "$assets/icon.png" ]
[ -f "$assets/icon.svg" ]
LANDESK_CODESIGN_IDENTITY=${LANDESK_CODESIGN_IDENTITY:-$(git -C "$repo_dir" config --get landesk.codesignIdentity || true)}
export LANDESK_CODESIGN_IDENTITY
: "${LANDESK_CODESIGN_IDENTITY:?Set the existing fixed signing certificate}"
# Refuse ad-hoc installations; migrate using the signed app installer first.
if codesign -dv "$app_path" 2>&1 | grep -q '^Signature=adhoc$'; then
  echo 'Migrate to a certificate-signed app before refreshing icons.' >&2
  exit 1
fi
python3 "$repo_dir/scripts/generate_localdesk_icons.py" --check
stage_dir=$(mktemp -d -t landesk-icons)
trap 'rm -rf "$stage_dir"' EXIT
stage_app="$stage_dir/LocalDesk.app"
ditto "$app_path" "$stage_app"
framework="$stage_app/Contents/Frameworks/App.framework"
assets="$framework/Versions/A/Resources/flutter_assets/assets"
cp "$repo_dir/flutter/macos/Runner/AppIcon.icns" "$stage_app/Contents/Resources/AppIcon.icns"
cp "$repo_dir/flutter/assets/icon.png" "$assets/icon.png"
cp "$repo_dir/flutter/assets/icon.svg" "$assets/icon.svg"
python3 "$repo_dir/tools/localdesk/install-macos.py" "$stage_app" --destination "$app_path"
