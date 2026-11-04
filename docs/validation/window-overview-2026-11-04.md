# Mobile window overview

## Behavior

- The mobile session rail shows **All windows / 所有窗口** for macOS, Windows and Linux peers.
- Windows sends a complete Win+Tab chord. macOS sends Control+Up instead of ordinary F3.
- Linux has no assumed system-wide binding. The first tap opens a shortcut editor. After saving, subsequent taps send that chord. Operations > Window overview shortcut reopens the editor.
- The Linux editor accepts a single key and optional Ctrl, Alt, Shift and Super modifiers. Selecting a modifier as the main key does not press that modifier twice.
- Saving does not trigger the shortcut. Cancel does not change the configuration. Save errors remain visible in the editor and allow retry.
- Linux configuration uses `sessionSetFlutterOption` / `sessionGetFlutterOption`, key `window-overview-shortcut`. These APIs write/read the current peer's `PeerConfig.ui_flutter`; the setting is not global.
- Unknown/corrupt stored shortcuts reopen configuration rather than sending an unknown key.
- Extra taps are ignored while an overview action or editor is already open. View-only sessions cannot trigger the rail action.

The macOS legacy input backend also preserves the Fn and numeric-pad flags intrinsic to arrow keys. The old injected Control+Up events were observed on the host without those flags; macOS's registered symbolic arrow shortcuts include the Fn modifier. The updated native host library has compiled and a same-identity signed candidate exists, but host installation and Mission Control acceptance remain pending.

## Verified

- 14 Flutter tests passed across `window_overview_test.dart`, `remote_shortcut_test.dart` and `remote_session_sidebar_test.dart`.
- Chord tests check the emitted Windows and macOS modifier/main-key order and release flags.
- Editor tests cover malformed configuration, custom-chord restoration, cancel, failed-save retry, both themes, portrait/landscape/tablet layouts and 2x text scaling.
- Static analysis: no new diagnostics; the existing `WillPopScope` deprecation in `remote_page.dart` remains.
- Production iOS simulator Xcode build succeeded, installed and launched on iPhone 17 Pro / iOS 26.5.
- On that simulator, an isolated UI preview using the production editor and theme was operated through Midscene/WDA: select Up, save Super+Up, reopen with that selection retained, switch to dark mode and rotate to landscape. The editor scrolls and its actions remain accessible. The preview had **no remote host** and used an in-memory callback; it does not establish peer-file persistence or remote execution.
- Mac native release library compiled and the candidate app passed certificate signing and previous-identity compatibility checks.

Local evidence: `/tmp/landesk-overview-tests-final.log`, `/tmp/landesk-overview-analyze-final.log`, `/tmp/landesk-overview-production-build.log`, `/tmp/landesk-mission-rust.log`. Preview screenshots: `/tmp/landesk-mission-review/linux-overview-light-portrait.png` and `linux-overview-dark-landscape.png`.

## Remaining acceptance

1. On Windows, tap All windows and verify Task View stays open after the key is released; select a window and check subsequent ordinary input is unmodified.
2. On Linux, configure a working overview binding on the host first (including the overview feature/plugin when needed on Hyprland). Match it in the editor and verify remote execution.
3. Reconnect/restart the mobile client and verify the Linux binding returns. Connect to a second Linux peer with a different binding and check isolation.
4. Install the signed Mac host candidate and verify Control+Up expands and closes Mission Control through the production client, without concurrent physical keyboard/mouse actions. The native fix has not yet passed this acceptance.

No Windows/Linux remote-host success or TestFlight release is claimed by this record.
