# Mobile keyboard and chat overlay

## Changes

- Keep the remote input subtree at a stable position while floating keys are
  shown or hidden. The previous landscape-only wrapper was removed as keyboard
  visibility changed, remounting the focused input.
- Mount the session's BlockableOverlay around the remote body for the lifetime
  of the page, instead of assigning it only to temporary connection masks in the
  bottom bar. Chat and dialogs now target that persistent local overlay.
- Update the existing underlying OverlayEntry when its parent rebuilds, so
  requests to show the hidden text field actually reach the overlay subtree.
- Cancel the pending iOS physical-focus workaround when opening the software
  keyboard and guard delayed focus callbacks after page disposal.
- Keep text chat and supported-platform voice call entry points. They send
  messages over the current peer session (client/io_loop.rs and
  server/connection.rs), without adding account or relay services. iOS retains
  its existing text-chat entry; this change does not implement iOS voice calls.

## Validation

Six Flutter widget tests passed across remote_input_stack_test.dart and
custom_key_overlay_test.dart. They cover keyboard focus/input connection
preservation, content updates and insertion into the persistent session overlay,
plus existing virtual-key editing, profile persistence and modifier release.
These tests do not prove actual iOS keyboard behavior or end-to-end chat delivery.

Targeted Dart analysis has no errors or warnings (five pre-existing deprecation
information messages). `git diff --check` passed.

Logs: `/tmp/landesk-input88-tests.log`, `/tmp/landesk-input88-analyze.log`.

iOS release archive 88 built successfully and passed strict codesign verification
with the existing development identity/profile. Archive:
`flutter/build/ios/archive/Runner.xcarchive`. Build/sign logs:
`/tmp/landesk-iphone88-flutter.log`, `/tmp/landesk-iphone88-sign.log`.

## Pending real-device acceptance

The connected-device list currently reports the iPhone as unavailable. Install
the final build after reconnecting/unlocking (and resolving any developer trust
prompt), then verify landscape and portrait keyboard show/hide/typing, rotation
while typing, chat open/close and an actual message to/from the Mac. Voice-call
transport was inspected in code, not exercised in this run.
