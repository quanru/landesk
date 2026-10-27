#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
: "${FLUTTER_BIN:?Set FLUTTER_BIN to Flutter 3.24.5 flutter executable}"
: "${VCPKG_ROOT:?Set VCPKG_ROOT to device vcpkg root with installed/arm64-ios}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_ios:?Set to device libsodium pkgconfig directory}"
: "${PKG_CONFIG_LIBDIR_aarch64_apple_darwin:?Set to host libsodium pkgconfig directory}"
export SODIUM_USE_PKG_CONFIG=1 PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_ALL_STATIC=1
cd "$repo_dir"
cargo build --locked --features flutter,hwcodec --release --target aarch64-apple-ios --lib
cd flutter
XCODE_XCCONFIG_FILE="$repo_dir/tools/localdesk/device.xcconfig" "$FLUTTER_BIN" build ios --release --no-codesign
