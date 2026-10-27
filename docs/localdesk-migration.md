# LocalDesk cross-platform migration

Base: SubnetDesk cdde2030deb18dcc148c13063b52c747dd3b448e
(https://github.com/zibo-chen/SubnetDesk), itself derived from RustDesk.
AGPL-3.0 attribution is retained. This branch supersedes the initial iPad-only fork.

The base removes relay, rendezvous, NAT punching, KCP/WebSocket/WebRTC relay
transports and cloud account workflows across all native platforms. LocalDesk
further restricts endpoints and incoming source addresses to private IP ranges,
and disables online-update/plugin builds. LAN discovery only produces direct
endpoint candidates, never an Internet relay fallback.

Both endpoints must use the new LAN protocol (LocalDesk, or a compatible
SubnetDesk build). This is not compatible with stock RustDesk authentication.
Existing passwords/settings are not silently migrated or changed. Configure a
local username/password on each controlled host; fingerprint verification stays.
iOS is a controller only, as in the original application.

Private VPN addresses are supported for the user's existing Tailscale setup;
LocalDesk has no control over a VPN's own transport or relay decisions.

Custom iPad keys were migrated from quanru/localdesk a6660dd. No previous broad
connection guards are copied: the relay implementation has been removed upstream.

Validation results are appended after building; source gates are not proof of
successful physical-device sessions or absence of every possible OS network flow.

## Local validation (2026-10-27)

- LAN residual gate: passed. Checks production transport symbols and public server options.
- Branding/icon/Linux service packaging gate: passed (50 image assets).
- `hbb_common` LAN tests: 5 passed, including private-range boundaries, public
  IPv4/IPv6 rejection, mapped IPv4, invalid IDs and endpoints.
- Flutter virtual-key tests: 7 passed. These exercise event ordering and widget
  persistence, not remote OS shortcut execution.
- iOS device and arm64 simulator Rust libraries: release builds passed with Rust 1.82.
- Targeted Flutter analysis: no errors/warnings; 7 deprecation informational notices.
- iOS unsigned device app: release build passed (57.7 MB).
- iPad mini simulator app: built, installed and launched to the LocalDesk connection screen.
- Desktop/Android binaries and physical remote sessions: pending. Desktop installers
  and Rust CI started on GitHub; source preflight passed there too.
- Physical iPad launch of the earlier build was refused by iPadOS signing/trust;
  no successful real-device LAN session is claimed.

## Reproduce the iOS build

Use macOS/Xcode, Flutter 3.44.1, Rust 1.82 with `aarch64-apple-ios` and
`aarch64-apple-ios-sim`, cargo-expand 1.0.95, flutter_rust_bridge_codegen 1.80.1
(with uuid), CocoaPods and the vcpkg dependencies pinned by the CI workflow.
Clone recursively, or run `git submodule update --init --recursive`.

Set `FLUTTER_BIN`, `VCPKG_ROOT` (device libraries under installed/arm64-ios),
`PKG_CONFIG_LIBDIR_aarch64_apple_ios` (device libsodium), and
`PKG_CONFIG_LIBDIR_aarch64_apple_darwin` (host libsodium); then run
`tools/localdesk/build-ios.sh`. It generates the bridge and an unsigned device app.
Use your Apple signing team/profile to install. Signing credentials are not stored
in this repository.

For simulator builds, use simulator-targeted native dependencies, set
`BINDGEN_EXTRA_CLANG_ARGS_aarch64_apple_ios_sim=--target=arm64-apple-ios15.0-simulator`
and `PKG_CONFIG_LIBDIR_aarch64_apple_ios_sim`, build the Rust library with
`cargo build --locked --features flutter --release --target aarch64-apple-ios-sim --lib`,
then run `XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/device.xcconfig" flutter build ios --simulator --debug --no-codesign` under `flutter/` (Apple Silicon only).
Xcode selects the matching library through `RUSTDESK_TARGET`.

Only private IPv4/IPv6 literals are accepted; hostnames are intentionally rejected
to prevent DNS from selecting a public endpoint. Link-local IPv6 scope identifiers
are not yet supported; use a LAN IPv4 or ULA IPv6 address instead.

## Development signing and launch failures

`tools/localdesk/sign-ios.py --identity <certificate-SHA1> --profile <profile-path>`
signs the built device app and its embedded frameworks, then verifies the result.
The Runner entitlement file does not request unused push/Wi-Fi-information
capabilities. The signing helper derives application/team/keychain entitlements
from the selected local profile. No certificate or provisioning profile is committed.

A successful `devicectl` installation is not proof that iPadOS permits launch.
A CoreDevice launch denial mentioning invalid signature, inadequate entitlements
or an untrusted profile must be resolved before claiming real-device validation.
The user may need to trust/verify the developer in Settings > General > VPN &
Device Management. Do not delete other apps, reset device trust or revoke working
certificates as a speculative workaround.

## Local Apple Silicon desktop build

`tools/localdesk/build-macos-arm64.sh` uses Flutter 3.44.1, Rust 1.82, existing
vcpkg `arm64-osx` libraries and host libsodium. Set `FLUTTER_BIN`, `VCPKG_ROOT`,
`VCPKG_INSTALLED_ROOT` if needed, and libsodium pkg-config environment variables.
It builds the library and service, packages the Flutter app for arm64/macOS 12.3+,
and refreshes/verifies the ad-hoc signature after embedding the service.
This local development recipe uses software codecs; it does not enable `hwcodec`.
The CI installer recipe separately enables hardware codecs.

Install the resulting `flutter/build/macos/Build/Products/Release/LocalDesk.app`
into `/Applications`. To serve a desktop, configure local access credentials in
LocalDesk and allow its screen recording/accessibility permissions in macOS.
Installation and opening the UI alone do not verify remote screen/input access.
