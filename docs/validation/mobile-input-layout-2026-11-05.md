# Mobile controls and viewport follow-up

## Changes

- Restore Tab (`VK_TAB`) in the default virtual-key column. An inherited unmodified T in that exact default slot is repaired on load; custom bindings and layouts are retained.
- Label the virtual mouse action as Right / 右键 and show a pressed state. It sends a right click at the current remote pointer; it is not a mouse-mode toggle. The rail's Touch mode / Mouse mode remains the mode selector.
- Collapse the rail to one 48-point overlay button. The collapsed canvas now uses the full width instead of reserving an empty 48-point strip.
- In landscape, an expanded rail reserves equal left and right margins so the canvas is horizontally centered. The remote-session backdrop is explicitly black in both app themes, so its reserved margins never inherit the light Scaffold background. Portrait keeps the existing right-side reservation. Canvas viewport measurements still come from its actual layout constraints.
- The same edge button hides the software keyboard while open. Remove the competing keyboard-hide floating action button; the gesture-help close action remains available.

## Validation

- 12 targeted Flutter tests passed (single test worker): sidebar centering and collapse, background hit testing, input-focus preservation, virtual-key storage/editing and held-key releases, right-button labeling and feedback, one-finger left/two-finger right taps and pinch isolation.
- The initial full run found stale T expectations; those now assert Tab and its actual emitted key. One storage restoration check also failed under concurrent compile/test load before a later single-worker pass; its real-time file-load waits remain a known test limitation.
- iPhoneOS Release UI linked against the existing current-source device core successfully. The resulting 1.5.1 (100) candidate was development signed and passed strict deep verification.
- Initial reproduction status (superseded by physical follow-up below): at reproduction time the iPhone 15 Pro was disconnected/unavailable and the Mac was locked. PUA startup could not find that USB device. The existing Mac server still listened on port 21118; that alone does not prove remote keyboard permission or working host input injection.
- At that initial checkpoint installation and physical acceptance were pending; see the completed physical follow-up below.

Local logs: `/tmp/landesk-input-layout-tests.log`, `/tmp/landesk-input-layout-analyze.log`, `/tmp/landesk-iphone-input-layout-build.log`, `/tmp/landesk-iphone-layout-sign.log`.

## Physical follow-up

The phone was reconnected, the UI candidate was installed and launched, and the existing saved Mac connection was opened through Midscene/WDA. Screenshots confirmed Tab, the labeled right button, a single collapsed rail button and horizontal canvas centering. The left margin initially exposed a white Scaffold background; the explicit black backdrop and both-theme regression assertion fix that follow-up. Physical control recovered after the Mac event-loop fix; see `macos-input-main-loop-2026-11-05.md`.

The final UI test run passed all 12 targeted tests. The final iPhoneOS build passed and was development signed. Phone report ID: `b66b3f97bd7641ba9d28f6661ddb705d`. Runtime screenshots are local under `~/.local/share/iphone-use/artifacts/`.

The final black-backdrop candidate was installed on the physical iPhone 15 Pro without removing app data. After launch, its saved remote session resumed. The expanded landscape screenshot confirms a black left gutter with the remote canvas centered; the white chat popup initially on top was closed before evaluating the backdrop. Screenshot: `/Users/bytedance/.local/share/iphone-use/artifacts/20261105T110532326880Z-9a0c6784.jpg`. Final build/sign logs: `/tmp/landesk-iphone-black-gutters.log`, `/tmp/landesk-iphone-black-sign.log`.
