# Connection initialization and macOS hot corners

## Cause and change

The first decoded frame calls `initializeCursorAndCanvas`. Without a saved
desktop canvas, this called `updateDisplayOrigin` with its default
`updateCursorPos: true`, sending a mouse move to the display origin (normally
`0,0`). Restoring a saved canvas also sent the display origin rather than the
saved cursor position. Either path could activate a host hot corner.

First-frame initialization now updates only local geometry, preserving the
cursor position already received from the peer. Saved-canvas restoration also
updates only local state. Actual user input and explicit display-switch behavior
are unchanged. Host hot-corner settings were not modified.

## Regression evidence

`flutter test test/cursor_initialization_test.dart --reporter expanded`

- Run against pre-fix HEAD: both tests failed. The initialization/reconnection
  case recorded three `Offset(0, 0)` moves; the offset-display restore case
  recorded `Offset(-1920, 0)`.
- Run against the fix: both tests passed. No mouse events were sent; the existing
  cursor location and restored display-relative coordinates were preserved.
- Test-file analysis: no issues. Analysis of model.dart reports existing warnings
  and informational findings outside the changed code; no compile errors.
- `git diff --check`: passed.

Logs: `/tmp/landesk-cursor-before.log`, `/tmp/landesk-cursor-after.log`,
`/tmp/landesk-cursor-analyze.log`, `/tmp/landesk-cursor-test-analyze.log`.

## Device build and remaining acceptance

iOS release archive 86 built successfully and passed strict codesign verification
with the existing development identity and provisioning profile. Rust code was
unchanged; the existing native library was reused.

Archive: `flutter/build/ios/archive/Runner.xcarchive`.
Logs: `/tmp/landesk-iphone86-flutter.log`, `/tmp/landesk-iphone86-sign.log`.

macOS release build 86 also built and was installed at
`/Applications/LocalDesk.app`. The installer verified the existing signing
identity and strict signature, preserved system permissions, and restarted the
GUI and user-session server. Installed CFBundleVersion was verified as 86.
Logs: `/tmp/landesk-macos86-flutter.log`, `/tmp/landesk-macos86-install.log`.

At this point, the phone is paired but locked. Xcode reports
`Unlock Leyang's iPhone 15 Pro to Continue`; the WDA startup is waiting for it.
Installation and real-device connection acceptance remain pending. Unit-test
evidence does not establish that the visible popup is eliminated on the phone.

After unlocking: install build 86, place the Mac pointer away from corners,
connect without touching the remote image, and check the pointer remains in
place with no hot-corner UI. Disconnect/reconnect and repeat; then verify touch
clicks, dragging and the dedicated scroll control still work.
