# LanDesk connection and input polish — 2026-10-27

## Implemented

- Mobile and desktop connect forms collapse credentials by default. Normal connection uses the existing native saved-credential/challenge flow. Expanding the form permits an explicit credential override; hiding it clears the transient password.
- Device cards prefer aliases/hostnames, with IP addresses secondary. Session events drive connecting, authentication, connected and failed feedback. Transport establishment alone is not treated as authenticated success. Failed/authentication states offer retry, routed to the owning desktop window or a fresh connection if that window has closed.
- Attempt/revision ordering rejects stale window events; the in-memory activity store is bounded to 128 endpoints and contains no credentials. Closing a failed session retains its reason but removes the live retry callback.
- Tablet connection form is 296 logical pixels wide; device content is capped at 520. List rows expand for status feedback rather than clipping it.
- Shared settings section cards, native list rows and switches replace the mobile settings package presentation. Mobile connection/display/input/appearance options are grouped, and desktop settings use the same section component and constrained width.
- Held virtual keys have animated pressed borders. The independent wheel shows drag direction. Window metric changes release held keys and stop wheel ownership; the overlay is hidden while the software keyboard or gesture help is visible.

No connection protocol, native credential storage, LAN policy, account or relay functionality was added or changed in this change set.

## Verified

From `flutter/`, with Flutter 3.44.1:

```sh
flutter test test/connection_activity_test.dart test/mobile test/mobile_peer_layout_test.dart test/landesk_theme_test.dart
flutter analyze --no-pub lib
XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/device.xcconfig" flutter build ios --simulator --debug --no-codesign
XCODE_XCCONFIG_FILE="$PWD/../tools/localdesk/macos-arm64.xcconfig" flutter build macos --release
```

- 39 tests passed, including stale-session ordering, closed-session retry removal, event classification, bounded storage, multi-touch key release and wheel cancellation after resize.
- Analyzer: no errors; repository warnings and informational diagnostics remain, so this is not a warning-free gate.
- iOS simulator debug and macOS release builds passed. These builds reuse existing native Rust artifacts; they do not prove the latest native credential implementation was rebuilt.
- Installed and launched on iPad mini A17 Pro and iPhone 16 simulators. Actual home screenshots checked for collapsed credentials, device label hierarchy and layout fit. After rebooting the simulator to clear the system prompt, the dark home screen was also captured and inspected (`/tmp/landesk-five-dark.png`); appearance was restored to light.

Local evidence: `/tmp/landesk-five-tests-final.log`, `/tmp/landesk-five-analyze-final.log`, `/tmp/landesk-five-sim.log`, `/tmp/landesk-five-macos.log`, `/tmp/landesk-five-ipad.png`, `/tmp/landesk-five-phone.png`.

## Not yet verified

- Saved credentials against a real authenticated host, desktop cross-window retry end to end, and physical iPhone/iPad remote key/scroll behavior.
- Interactive navigation through settings and dark-mode dialogs in the final build. Native GUI automation could not acquire the simulator window (`cgWindowNotFound`). A URL connection attempt stopped at the iOS “Open in LanDesk?” system prompt, not at successful authentication.
- The built macOS app has not replaced the installed application or background service in this pass. Windows, Linux and Android builds were not run.

Remaining acceptance: rebuild native artifacts for the intended targets, install with the existing signing identity, connect to a LAN host, restart to verify saved credentials, exercise error/retry and settings in both themes, then test held Cmd+Space and wheel dragging on the physical devices.
