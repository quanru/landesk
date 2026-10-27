#!/bin/sh
# Build the production LocalDesk client for an Apple Silicon iOS simulator.
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
: "${FLUTTER_BIN:?Set FLUTTER_BIN to Flutter 3.44.1}"
: "${VCPKG_ROOT:?Set VCPKG_ROOT to simulator-targeted vcpkg dependencies}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_ios_sim:?Set simulator libsodium pkgconfig directory}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_darwin:?Set host libsodium pkgconfig directory}"
export SODIUM_USE_PKG_CONFIG=1 PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_ALL_STATIC=1
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_apple_ios_sim=--target=arm64-apple-ios15.0-simulator
cd "$repo_dir"
"${BRIDGE_CODEGEN_BIN:-flutter_rust_bridge_codegen}" \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/ios/Runner/bridge_generated.h
cargo build --locked --features flutter --release --target aarch64-apple-ios-sim --lib
cd flutter
XCODE_XCCONFIG_FILE="$repo_dir/tools/localdesk/device.xcconfig" \
  "$FLUTTER_BIN" build ios --simulator --debug --no-codesign
if [ "$#" -gt 0 ]; then
  xcrun simctl bootstatus "$1" -b
  xcrun simctl install "$1" build/ios/iphonesimulator/Runner.app
  xcrun simctl launch --terminate-running-process "$1" dev.quanru.localdesk
fi
