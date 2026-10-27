#!/bin/sh
# Refresh branding in an existing ad-hoc development install without replacing
# its executable or changing launchd paths. Does not alter app data or TCC grants.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
app_path=${1:-/Applications/LocalDesk.app}
framework="$app_path/Contents/Frameworks/App.framework"
assets="$framework/Versions/A/Resources/flutter_assets/assets"
[ -f "$app_path/Contents/Resources/AppIcon.icns" ]
[ -f "$assets/icon.png" ]
[ -f "$assets/icon.svg" ]
# Never replace a Developer ID signature with an ad-hoc signature.
if ! codesign -dv "$app_path" 2>&1 | grep -q '^Signature=adhoc$'; then
  echo 'This helper only supports existing ad-hoc development installs.' >&2
  exit 1
fi
python3 "$repo_dir/scripts/generate_localdesk_icons.py" --check
cp "$repo_dir/flutter/macos/Runner/AppIcon.icns" "$app_path/Contents/Resources/AppIcon.icns"
cp "$repo_dir/flutter/assets/icon.png" "$assets/icon.png"
cp "$repo_dir/flutter/assets/icon.svg" "$assets/icon.svg"
codesign --force --sign - "$framework"
codesign --force --sign - --options runtime \
  --entitlements "$repo_dir/flutter/macos/Runner/UnsignedRelease.entitlements" "$app_path"
codesign --verify --deep --strict "$app_path"
touch "$app_path"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app_path"
