# Apple Silicon iOS simulator build

Prerequisites used during development:

- Xcode 27.1, iOS 26.5 simulator runtime, CocoaPods.
- Flutter 3.24.5 (as pinned by upstream CI), Rust 1.81.0 with rustfmt.
- `cargo-expand` 1.0.95 and `flutter_rust_bridge_codegen` 1.80.1 (`--features uuid`).
- vcpkg at `9e593bb18ea69cc5095e012465dcd675a822ed0d`, bootstrapped.
- CMake, Ninja, NASM, YASM, pkg-config and recursive Git submodules.

```sh
cargo install cargo-expand --version 1.0.95 --locked
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
export VCPKG_ROOT=/path/to/vcpkg
export FLUTTER_BIN=/path/to/flutter/bin/flutter
export PATH="$(dirname "$FLUTTER_BIN"):$HOME/.cargo/bin:$PATH"
./tools/ios_simulator/build.sh
```

Use a dedicated dependency install root; do not reuse device libraries. The
script builds libsodium from the exact source bundled with the locked
libsodium-sys dependency, avoiding its outdated target detection. Separate host/target pkg-config paths
prevent the macOS build script from linking the simulator archive. The target-
specific bindgen argument fixes CoreAudio's old simulator target spelling.

The generated native library is `target/aarch64-apple-ios-sim/release/liblibrustdesk.a`.
The Xcode project selects it only for the simulator SDK. The build omits
`hwcodec` and uses portable-C libvpx on the simulator. Production device flags
and libraries are unchanged. FFmpeg may be installed by the existing manifest,
but its device-only build is not linked into this simulator configuration.

To install a successful full-client build (not the component preview):

```sh
xcrun simctl install SIMULATOR_UDID flutter/build/ios/iphonesimulator/Runner.app
xcrun simctl launch SIMULATOR_UDID com.carriez.flutterHbb
```

## Restricted source-host connectivity

If Google source hosts are unreachable, these per-command Git mappings were
used locally. Git still checks out the repository's pinned commit IDs; no global
Git configuration or dependency version is changed.

```sh
GIT_CONFIG_COUNT=3 \
GIT_CONFIG_KEY_0=url.https://github.com/webmproject/libwebm.insteadOf \
GIT_CONFIG_VALUE_0=https://chromium.googlesource.com/webm/libwebm \
GIT_CONFIG_KEY_1=url.https://github.com/arthenica/libaom.insteadOf \
GIT_CONFIG_VALUE_1=https://aomedia.googlesource.com/aom \
GIT_CONFIG_KEY_2=url.https://github.com/lemenkov/libyuv.insteadOf \
GIT_CONFIG_VALUE_2=https://chromium.googlesource.com/libyuv/libyuv \
./tools/ios_simulator/build.sh
```

See `docs/ipad-virtual-keys.md` for the actual validation state. A build recipe
alone is not evidence of a running full client or remote input acceptance.
