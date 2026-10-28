#!/bin/sh
# Local Apple Silicon development build using preinstalled vcpkg dependencies.
set -eu
cd "$(dirname "$0")/../.."
repo_dir="$PWD"
: "${FLUTTER_BIN:?Set FLUTTER_BIN to Flutter 3.44.1}"
LANDESK_CODESIGN_IDENTITY=${LANDESK_CODESIGN_IDENTITY:-$(git config --get landesk.codesignIdentity || true)}
export LANDESK_CODESIGN_IDENTITY
: "${LANDESK_CODESIGN_IDENTITY:?Set a fixed Apple signing certificate; do not use ad-hoc signing}"
: "${VCPKG_ROOT:?Set VCPKG_ROOT with installed/arm64-osx libraries}"
# Generated bridges are ignored by Git; always derive them from the current API.
"${BRIDGE_CODEGEN_BIN:-flutter_rust_bridge_codegen}" \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/ios/Runner/bridge_generated.h
export MACOSX_DEPLOYMENT_TARGET=12.3
# Software codecs keep this local build independent of ffmpeg/hwcodec packages.
cargo build --locked --features flutter --release --lib --bin service
cp target/release/liblibrustdesk.dylib target/release/librustdesk.dylib
cd flutter
XCODE_XCCONFIG_FILE="$repo_dir/tools/localdesk/macos-arm64.xcconfig" \
  "$FLUTTER_BIN" build macos --release
app_path=build/macos/Build/Products/Release/landesk.app
cp ../target/release/service "$app_path/Contents/MacOS/service"
python3 "$repo_dir/tools/localdesk/sign-macos.py" "$app_path"
