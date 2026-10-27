# iPad virtual keys development record

Baseline: RustDesk tag `1.5.0`, commit
`fada664df7a294d1d1a9ca3e7cd3637069122f17`.
Branch: `feat/ipad-virtual-keys`.

The implementation starts from the supplied
`rustdesk-virtual-keys-mvp.zip` (SHA-256
`488f963121c9efb38a399ddaa07cff40939912d2a323815b40bc0a02e711c538`).
The archive contained a widget and integration instructions, not a built client.

## Implemented

- Nine keys including Cmd Space, configurable key/modifier combinations.
- Long press to edit; drag to position; tap the checkmark to finish editing.
- Visibility toggle and normalized layout persistence, separate Mac/Linux files.
- Mac Cmd Copy/Paste and Linux Ctrl Copy/Paste defaults. Linux terminal users can
  explicitly add Shift in the editor; active remote applications are not detected.
- Remote writer sends modifiers down, main key down/up, modifiers up in reverse
  order, including best-effort releases after a bridge exception.
- One in-flight shortcut at a time; existing held modifiers prevent a shortcut
  from starting. Sticky/held modifiers and macros are not implemented.
- iOS-only integration outside remote pointer and touch listeners. Permission,
  view-only, Wayland consent and session-closed checks are retained.

The shortcut layer does not change connection or transport code. This is not
proof that Tailscale/Direct IP regression tests have passed.

## Validation results (2026-10-27)

Flutter 3.24.5 / Dart 3.5.4; Xcode 27.1; iPad mini A17 Pro simulator, iOS 26.5.

- Three automated tests pass: complete Cmd Space sequence followed by Enter;
  release after a failed main-key write; widget hit testing, edit/hold/drag,
  disk restoration and hiding.
- The full RustDesk App built successfully, was installed on the iPad mini
  simulator, and opened its Chinese connection home screen. Bundle ID:
  `com.carriez.flutterHbb`. No remote session was configured.
- The ARM simulator Rust static library built successfully (`--features flutter`,
  release profile). Existing upstream compiler warnings remain.
- Static analysis of the two new modules and remote page passes with only two
  existing WillPopScope deprecation notices. Bridge generation completed.
- The component preview built, installed and ran on the simulator. Screenshots
  show all nine keys, the Cmd Space sequence, successful drag, unchanged position
  after process termination/relaunch, hiding, and portrait/landscape layout.
- Background pan and two-finger pinch work with the overlay visible. The preview
  recorded 75 movement updates and scale 1.59 after the pinch.
- A real simulator hold/drag initially failed because the long-press recognizer
  remained active in edit mode. Disabling that recognizer in edit mode fixed it;
  the regression test includes a held touch before movement.
- Midscene AI act failed with an expired model credential (401). Subsequent UI
  validation used screenshot-grounded direct WDA actions via Midscene CLI.

**The preview uses the production widget and sender with a logging writer. It is
not the full RustDesk client and has no remote host connection.** Remote command
execution, Tailscale, clipboard synchronization, suspension/disconnection cleanup,
physical-keyboard overlap, true iPad behavior and signed distribution remain
unverified. No signed IPA or end-to-end remote-session acceptance is claimed.

## Reproduce the component checks

```sh
cd flutter
flutter pub get
flutter test test/mobile --reporter expanded
flutter analyze --no-fatal-infos lib/mobile/widgets/custom_key_overlay.dart \
  lib/mobile/widgets/remote_shortcut.dart lib/mobile/pages/remote_page.dart
```

For component installation see `tools/virtual_keys_preview/README.md`.
For the full-client native build see `tools/ios_simulator/README.md`.
Local evidence is in `artifacts/virtual-keys/` (not committed):

- `rustdesk-full-client.png`, `full-client-build.log`, `native-build.log`.
- `cmd-space-sequence.png`, `drag-edit.png`, `restart-restored.png`.
- `hidden.png`, `landscape.png`, `canvas-pan.png`, `canvas-pinch.png`.
- `widget-tests.log`, `analysis.log`, `preview-script.log`.

The full App is `flutter/build/ios/iphonesimulator/Runner.app`. The component App
is `tools/virtual_keys_preview/build/ios/iphonesimulator/Runner.app`.
The native build steps were executed and verified individually; the assembled
full-build script was syntax-checked. The component build/install script was also
executed end to end.

 The local resolved
Dart/Pods lockfiles are captured there; upstream lockfiles are not intentionally
updated for this feature. Flutter 3.24.5 resolves some older dependencies than the
checked-in lockfile, as in upstream's build workflow.

## Full client build work

The upstream iOS workflow builds only `aarch64-apple-ios` (device). Simulator
builds need a separate native library, not a relabeled device archive. The Xcode
project now selects `aarch64-apple-ios-sim` only for the simulator SDK.

`tools/ios_simulator/simulator.xcconfig` overrides deployment target to iOS 15 and
architecture to arm64 for local Xcode 27. The production deployment target is
unchanged. `tools/ios_simulator/arm64-ios.cmake` is a simulator vcpkg triplet;
keep its installation directory separate from device dependencies.

The simulator native build uses `--features flutter` without `hwcodec`. The
upstream FFmpeg port forces device flags and is not suitable for simulator
linking. libvpx's simulator branch uses portable C because its arm64 Darwin
configuration also forces the device SDK. This is a validation build, not a
hardware-video performance baseline.

Google source hosts were unreachable. Temporary per-command Git URL mappings
used matching commits from GitHub mirrors for libwebm, aom and libyuv. No global
Git configuration was changed, and dependency revisions were not upgraded.

`libsodium-sys 0.2.7` rejects `aarch64-apple-ios-sim`. Supply a simulator-built
libsodium through target-specific pkg-config paths, and a separate host library
for Rust build scripts; do not mix macOS, simulator and device archives.

## Regression surface

- `flutter/lib/mobile/pages/remote_page.dart`: a wrapper adds the iOS shortcut
  layer outside existing input listeners. Other platforms return the original
  widget. No old pointer/key handler was rewritten.
- `flutter/ios/Runner.xcodeproj/project.pbxproj`: SDK-dependent Rust library path;
  device builds retain the original target.
- `res/vcpkg/libvpx/portfile.cmake`: only arm64 iOS simulator selects the portable
  compiler path; device and other platform branches are unchanged.

No protocol, connection, Tailscale, host permission, signing or remote settings
were changed. P1 size/opacity/per-connection profiles and P2 macros/import/export
remain outside this initial implementation.
