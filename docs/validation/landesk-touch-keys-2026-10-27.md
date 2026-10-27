# landesk branding and touch keyboard

- Public repository renamed to https://github.com/quanru/landesk; local fork remote updated.
- Display name is lowercase `landesk`. Existing bundle IDs, Keychain service, config names, local discovery service and URL scheme remain stable for installed clients.
- New original cartoon computer-user icon is in `res/landesk-icon.png`; `scripts/generate_localdesk_icons.py` generates the platform sizes and verifies the asset manifest.
- The always-visible keyboard toggle is a gray circle at the bottom left, aligned with the bottom row. Long press this toggle to edit the layout.
- Built-in keys are individual keys. Cmd / Opt / Ctrl and ordinary keys emit down on touch-down and up on release/cancellation. Multiple fingers can hold independent keys. Pressing Cmd and tapping Space does not release Cmd; Cmd+Tab remains held only while Cmd is physically touched.
- Old built-in Cmd+Tab / Cmd+Space buttons are removed on layout load. Old Copy/Paste buttons become plain C/V, preserving their size and position. User-created macros remain available but cannot start while another virtual key is held.
- Lifecycle changes, hiding the layer and disposal request release of all owned keys. Bridge failures attempt cleanup and report an error; successful transport is still required for the remote host to receive releases.

Validation so far: 10 Flutter tests passed, including multi-touch widget events, delayed transport ordering, shared modifier ownership, cancellation, cleanup and failure recovery. iOS native release build passed. Branding and all 51 generated icon checks passed.

Real iPhone-to-Mac multi-touch shortcut acceptance and Linux/Windows/Android builds are not implied by these results. Config/Keychain identity preservation is an implementation property, not yet a measured upgrade acceptance result.

Final build results: iOS release (61.1 MB) and macOS arm64 release (58.7 MB) both passed. iOS development signature and macOS ad-hoc deep/strict signature checks passed. Built iOS `CFBundleDisplayName` and macOS `CFBundleName` both read `landesk`.

Installation was attempted on iPhone UDID ending `0160001C`, but CoreDevice reports `unavailable` and installation returned error 4016 (device usage assertions unavailable). The new version has not been installed on that phone. The existing Mac installation has not been replaced; the signed new build is at `flutter/build/macos/Build/Products/Release/landesk.app`.

Logs: `/tmp/landesk-hold-tests.log`, `/tmp/landesk-held-rust.log`, `/tmp/landesk-held-flutter.log`, `/tmp/landesk-ios-sign.log`, `/tmp/landesk-ios-install.log`, `/tmp/landesk-host-rust.log`, `/tmp/landesk-host-flutter.log`.
