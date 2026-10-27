#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
: "${FLUTTER_BIN:?Set FLUTTER_BIN to Flutter 3.44.1 flutter executable}"
: "${VCPKG_ROOT:?Set VCPKG_ROOT to device vcpkg root with installed/arm64-ios}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_ios:?Set to device libsodium pkgconfig directory}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_darwin:?Set to host libsodium pkgconfig directory}"
# Bridge code generation also invokes Flutter by name.
export PATH="$(dirname -- "$FLUTTER_BIN"):$PATH"
export SODIUM_USE_PKG_CONFIG=1 PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_ALL_STATIC=1
cd "$repo_dir"
"$FLUTTER_BIN" --version
(cd flutter && "$FLUTTER_BIN" pub get)
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/ios/Runner/bridge_generated.h
cargo build --locked --features flutter,hwcodec --release --target aarch64-apple-ios --lib
cd flutter
XCODE_XCCONFIG_FILE="$repo_dir/tools/localdesk/device.xcconfig" "$FLUTTER_BIN" build ios --release --no-codesign
