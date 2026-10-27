# Minimal theme and common repository rename — 2026-10-27

## Delivered

- Renamed the actual GitHub repository from `quanru/localdesk-common` to `quanru/landesk-common`; verified the returned repository name/URL using GitHub API.
- Updated `.gitmodules`, synchronized the local submodule configuration and updated the branding check. The pinned common commit remains `b483302be815c9bb0b73cef5fea7fe86a7bc7ede`.
- Implemented the vibelet minimal / 素雅 design language in Flutter for system, light and dark appearance. See `docs/design/suya-theme.md` for component coverage and design values.
- Studio was inspected through selected GitHub API reads only; it was not cloned or pulled.

## Checks

- 35 Flutter tests passed: theme component/platform configurations and contrast, component layout, virtual keyboard/mouse regression and macOS font fallback.
- Full Flutter library analysis: zero errors; 297 warnings/info remain (including deprecated APIs). This is not a clean analyzer pass.
- `scripts/check_localdesk_branding.sh`: passed.
- `git diff --check`: passed.
- macOS arm64 Release Flutter build: passed (`build/macos/Build/Products/Release/landesk.app`).
- iOS device Release Flutter build: passed, unsigned (`build/ios/iphoneos/Runner.app`).
- iOS simulator Debug Flutter build: passed. Initial Xcode package resolution failed without a diagnostic; retry resolved packages and completed. Final incremental build also passed.
- Installed and launched the final simulator app on iPad mini (A17 Pro), UDID `6E387569-DB27-4123-9377-A740540BC264`; simctl returned process 23679.

Build commands, from `flutter/`, using Flutter 3.44.1 and the existing native archives:

```sh
XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/macos-arm64.xcconfig" flutter build macos --release
XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/device.xcconfig" flutter build ios --release --no-codesign
XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/device.xcconfig" flutter build ios --simulator --debug --no-codesign
```

This is a Flutter theme-only change: native archives were reused, not rebuilt. Follow the existing platform build scripts for a clean checkout's native prerequisites.

## Remaining runtime acceptance

- Physical iPhone was unavailable in devicectl. No claim of updated physical-device installation or theme validation.
- Desktop automation could not read the macOS app window (timeout) or simulator window (`cgWindowNotFound`). The simulator launch is process evidence, not visual acceptance or end-to-end remote input verification.
- The installed `/Applications/LocalDesk.app` was not replaced by this task; the macOS build artifact contains the new UI.
- Windows, Linux, Android and web native/browser builds were not run. Shared target-platform widget coverage does not certify these runtimes.
- The theme does not alter connection routing, authentication, relay removal or virtual-key event sequencing; real remote-session regression remains separate from component tests.

Local execution logs: `/tmp/landesk-theme-tests-final.log`, `/tmp/landesk-theme-final-analyze.log`, `/tmp/landesk-theme-macos-final.log`, `/tmp/landesk-theme-ios-final.log`, `/tmp/landesk-theme-simulator-final.log`.
