#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

require_fixed() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq -- "$expected" "$file"; then
    printf 'Missing landesk branding in %s: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

require_fixed README.md '# landesk'
require_fixed Cargo.toml 'description = "landesk LAN/VPN Remote Desktop"'
require_fixed Cargo.toml 'ProductName = "landesk"'
require_fixed Cargo.toml 'identifier = "dev.quanru.localdesk"'
# Internal storage identity deliberately stays LocalDesk.
require_fixed libs/hbb_common/src/config.rs 'RwLock::new("LocalDesk".to_owned())'
require_fixed libs/hbb_common/src/config.rs 'RwLock::new("dev.quanru".to_owned())'
require_fixed src/common.rs '"LocalDesk" => "landesk".to_owned()'
require_fixed flutter/android/app/build.gradle 'applicationId "dev.quanru.localdesk"'
require_fixed flutter/android/app/src/main/res/values/strings.xml '<string name="app_name">landesk</string>'
require_fixed flutter/ios/Runner/Info.plist '<string>dev.quanru.localdesk</string>'
require_fixed flutter/ios/Runner/Info.plist '<string>localdesk</string>'
require_fixed flutter/macos/Runner/Configs/AppInfo.xcconfig 'PRODUCT_NAME = landesk'
require_fixed flutter/macos/Runner/Configs/AppInfo.xcconfig 'PRODUCT_BUNDLE_IDENTIFIER = dev.quanru.localdesk'
require_fixed flutter/windows/runner/Runner.rc 'VALUE "ProductName", "landesk"'
require_fixed flutter/linux/CMakeLists.txt 'set(APPLICATION_ID "dev.quanru.localdesk")'
require_fixed flatpak/rustdesk.json '"id": "dev.quanru.LocalDesk"'
require_fixed flatpak/dev.quanru.LocalDesk.metainfo.xml '<name>landesk</name>'
require_fixed res/rustdesk.desktop 'Name=landesk'
require_fixed res/localdesk.service 'Description=landesk'
require_fixed .gitmodules 'https://github.com/quanru/localdesk-common.git'
require_fixed build.py 'Build/Products/Release/landesk.app'
require_fixed .github/workflows/flutter-build.yml 'Build/Products/Release/landesk.app'
require_fixed .github/workflows/flutter-build.yml 'localdesk-${{ env.VERSION }}'

if grep -Fq 'RustDesk.app' .github/workflows/flutter-build.yml; then
  printf 'Release workflow still references RustDesk.app\n' >&2
  exit 1
fi

for stale in \
  flutter/ios/Runner/GoogleService-Info.plist \
  flutter/ios/exportOptions.plist \
  flatpak/com.rustdesk.RustDesk.metainfo.xml \
  .github/workflows/fdroid.yml; do
  if [[ -e "$stale" ]]; then
    printf 'Stale upstream release file is still present: %s\n' "$stale" >&2
    exit 1
  fi
done

python3 scripts/generate_localdesk_icons.py --check
bash scripts/check_linux_service_branding.sh
printf 'landesk branding and generated icons are consistent.\n'
