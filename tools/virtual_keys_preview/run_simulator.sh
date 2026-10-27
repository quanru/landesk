#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
flutter_bin="${FLUTTER_BIN:-flutter}"
simulator_id="${1:?Pass the UDID of an available iPad simulator}"
"$flutter_bin" create --platforms ios --org dev.quanru --project-name virtual_keys_preview --no-pub .
python3 - <<'PYTRANS'
import json, re
from pathlib import Path
source = Path('../../src/lang/cn.rs').read_text()
entries = dict(re.findall(r'\("([^"\\]*)", "([^"\\]*)"\)', source))
Path('lib/preview_translations.dart').write_text('// Generated from src/lang/cn.rs.\nconst previewTranslations = ' + json.dumps(entries, ensure_ascii=False) + ';\n')
PYTRANS
mkdir -p .dart_tool
cat > .dart_tool/simulator.xcconfig <<'CONFIG'
IPHONEOS_DEPLOYMENT_TARGET = 15.0
ARCHS = arm64
ONLY_ACTIVE_ARCH = YES
CONFIG
XCODE_XCCONFIG_FILE="$PWD/.dart_tool/simulator.xcconfig" \
  "$flutter_bin" build ios --simulator --debug --no-codesign
xcrun simctl boot "$simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl install "$simulator_id" build/ios/iphonesimulator/Runner.app
xcrun simctl terminate "$simulator_id" dev.quanru.virtualKeysPreview 2>/dev/null || true
xcrun simctl launch "$simulator_id" dev.quanru.virtualKeysPreview
