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
- Visibility toggle and normalized layout persistence per peer ID and remote OS; existing v2 OS layouts seed new profiles.
- Mac Cmd Copy/Paste and Linux Ctrl Copy/Paste defaults. Linux terminal users can
  explicitly add Shift in the editor; active remote applications are not detected.
- Remote writer sends modifiers down, main key down/up, modifiers up in reverse
  order, including best-effort releases after a bridge exception.
- One in-flight shortcut at a time; existing held modifiers prevent a shortcut
  from starting. Sticky/held modifiers are not implemented. Macros execute complete chords sequentially.
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
were changed. Layout import/export and sticky modifiers remain outside this implementation.


## Customization update (2026-10-27)

- Long press any key or the controller to edit. Use **+** to add a key; tap a key
  to edit or delete it. The controller remains available even after deleting all keys.
- Each key has a label, size (44–120 logical points), background opacity (15–100%),
  and 1–20 shortcut steps. Text remains opaque for readability. Up/down controls
  reorder steps; each step has its own key and modifiers. A shared interval
  (0–2000 ms) separates steps. Each tap runs the sequence once, without loops.
- **Stop macro** cancels subsequent steps after the current chord is released.
  Leaving the overlay or backgrounding the app also cancels subsequent steps.
  A failed send stops the sequence. Timing is local and does not wait for a remote
  application to finish responding; no real-host macro timing claim is made.
- Up to 40 keys per layout. Profiles use the connection's peer ID, not the transient
  session UUID. Connecting to the same machine through a different ID/IP creates
  a separate profile. All edits persist locally; there is no cloud sync.
- Preview's Mac A / Mac B switch demonstrates independent profiles; neither is a
  real remote host. Its production modules remain symlinked, not copied.

Validation: five automated tests pass, including add/edit/delete, appearance and
macro disk round-trip, independent peer profiles, macro order/cancellation/failure,
and the original input/drag tests. Full client and preview simulator builds pass;
the updated full client is installed. Targeted analysis has no errors/warnings;
three info notices remain (two upstream WillPopScope deprecations and the existing
test's transitive path_provider_platform_interface import).

Device Hub UI verification: created a two-step Esc/Enter macro, observed the four
ordered down/up events, switched to Mac B (macro absent) and back to Mac A (macro
restored), and changed its size to 82 pt and background opacity to 58% using sliders.
After terminating and relaunching the preview, the editor still showed 82 pt, 58%,
and both macro steps.
Evidence: `extended-tests.log`, `extended-analysis.log`, `extended-full-build.log`,
`extended-preview-build.log`, `extended-macro.png` in the local evidence directory.

Regression surface for this update: `custom_key_overlay.dart` changes only this
feature's layout/editor/send flow; `remote_shortcut.dart` adds the macro runner
without changing the chord writer; `remote_page.dart` passes the stable peer ID
and reports unavailable input as an error so macros stop instead of silently
continuing. Preview and feature tests change to exercise the new UI. No transport,
Rust protocol, native build or existing keyboard/pointer handling changed.

## RustDesk visual integration (2026-10-27)

The overlay now inherits RustDesk's `ThemeData`: themed dialog surfaces and text,
blue secondary color for editing, 8-point key corners consistent with existing
buttons, keyboard icons, and themed ElevatedButton actions. The editor is divided
into Key settings / Key appearance / Macro steps tabs. Each page scrolls inside a
height constrained by the viewport and keyboard; the Save/Cancel actions stay
outside the scroll area. No app-wide theme was modified.

The remote-page hook passes RustDesk's `translate` callback. New UI strings use
`src/lang/cn.rs` for Simplified Chinese and English source keys as fallback. Other
locale files receive empty placeholders as required by AGENTS.md; Italian is not
machine-translated. Existing translation entries are preserved. The preview
build generates its Chinese dictionary from that same source, and offers language
and theme switches. Its lightweight theme matches the relevant RustDesk Material 2
colors/shapes; the full client's component uses the actual inherited app theme.

Validation: all five feature tests pass after the tab navigation change; targeted
analysis passes with only the two pre-existing WillPopScope notices. The updated
Rust native library and full simulator client build successfully. Device Hub
visually verified the Chinese light editor and English dark macro page, including
tab navigation and restoration of the existing macro. The initial preview exposed
invisible light-theme tab labels; explicit theme foregrounds fixed it and the
corrected screenshots were reviewed. Evidence: `themed-tests.log`,
`themed-analysis.log`, `themed-native-build.log`, `themed-full-build.log`,
`themed-preview-build.log`, `themed-light-cn.png`, `themed-dark-en.png`.

Regression surface: the two virtual-key UI files change only appearance,
localization and editor organization; `remote_page.dart` supplies translation;
`src/lang/*.rs` append feature strings/placeholders; preview files and the existing
widget test adapt to the new tabs/theme. Shortcut execution, layout storage,
connection protocol and existing remote pointer/keyboard handlers are unchanged.
Real remote-desktop visual acceptance and iPad hardware testing remain pending.
