#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
flutter_bin="${FLUTTER_BIN:-flutter}"
simulator_id="${1:?Pass the UDID of an available iPad simulator}"
"$flutter_bin" create --platforms ios --org dev.quanru --project-name virtual_keys_preview --no-pub .
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
