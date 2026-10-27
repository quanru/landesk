#!/bin/bash
# Apple Silicon simulator build. Does not sign or change device build settings.
set -euo pipefail
cd "$(dirname "$0")/../.."
repo_dir="$PWD"
: "${VCPKG_ROOT:?Set VCPKG_ROOT to vcpkg at the repository baseline revision}"
flutter_bin="${FLUTTER_BIN:-flutter}"
export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-1.81.0}"
export IPHONEOS_DEPLOYMENT_TARGET=15.0
export BINDGEN_EXTRA_CLANG_ARGS_aarch64_apple_ios_sim='--target=arm64-apple-ios15.0-simulator'
export VCPKG_INSTALLED_ROOT="${VCPKG_INSTALLED_ROOT:-$repo_dir/target/ios-simulator/deps}"
simulator_work_dir="$repo_dir/target/ios-simulator"
mkdir -p "$simulator_work_dir"
rustup target add aarch64-apple-ios-sim

"$VCPKG_ROOT/vcpkg" install --triplet arm64-ios \
  --overlay-triplets="$repo_dir/tools/ios_simulator" \
  --x-install-root="$VCPKG_INSTALLED_ROOT"

cargo metadata --locked --format-version 1 > "$simulator_work_dir/metadata.json"
sodium_source_dir="$(python3 - "$simulator_work_dir/metadata.json" <<'PY'
import json, pathlib, sys
packages = json.load(open(sys.argv[1]))['packages']
package = next(p for p in packages if p['name'] == 'libsodium-sys')
print(pathlib.Path(package['manifest_path']).parent / 'libsodium')
PY
)"
mkdir -p "$simulator_work_dir/sodium-build"
(
  cd "$simulator_work_dir/sodium-build"
  CC="$(xcrun --sdk iphonesimulator --find clang)" \
  CFLAGS="-target arm64-apple-ios15.0-simulator -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path)" \
    "$sodium_source_dir/configure" --host=aarch64-apple-darwin \
    --disable-shared --enable-static --prefix="$simulator_work_dir/sodium"
  make -j8
  make install
)
# RustDesk also links libsodium into a macOS build script. Keep host and target
# libraries separate and let pkg-config select by Cargo TARGET.
mkdir -p "$simulator_work_dir/sodium-host-build"
(
  cd "$simulator_work_dir/sodium-host-build"
  "$sodium_source_dir/configure" --disable-shared --enable-static \
    --prefix="$simulator_work_dir/sodium-host"
  make -j8
  make install
)
unset SODIUM_LIB_DIR
export SODIUM_USE_PKG_CONFIG=1
export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_ALL_STATIC=1
export PKG_CONFIG_LIBDIR_aarch64_apple_ios_sim="$simulator_work_dir/sodium/lib/pkgconfig"
export PKG_CONFIG_LIBDIR_aarch64_apple_darwin="$simulator_work_dir/sodium-host/lib/pkgconfig"
(
  cd flutter
  "$flutter_bin" pub get
)
flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/ios/Runner/bridge_generated.h
# magnum-opus still reads VCPKG_ROOT/installed and ignores the install-root override.
mkdir -p "$simulator_work_dir/vcpkg"
ln -sfn "$VCPKG_INSTALLED_ROOT" "$simulator_work_dir/vcpkg/installed"
VCPKG_ROOT="$simulator_work_dir/vcpkg" \
  cargo build --locked --features flutter --release --target aarch64-apple-ios-sim --lib
(
  cd flutter
  XCODE_XCCONFIG_FILE="$repo_dir/tools/ios_simulator/simulator.xcconfig" \
    "$flutter_bin" build ios --simulator --debug --no-codesign
)
