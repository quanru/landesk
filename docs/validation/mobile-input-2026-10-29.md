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

## iPhone simulator follow-up

- Booted iPhone 17 Pro / iOS 26.5 and built a separate simulator WDA runner.
- Rebuilt the current Rust simulator library. The first link used a device Opus
  archive because magnum-opus reads VCPKG_ROOT/installed directly. Rebuilt with
  `/tmp/landesk-sim-native/installed` pointing at simulator dependencies and
  `IPHONEOS_DEPLOYMENT_TARGET=15.0`; build passed.
- Installed and launched the production simulator client. Connecting reproduced
  a black screen: a non-positioned toolbar mask consumed the body height, leaving
  no room for the session login overlay. Fixed the mask to Positioned.fill and
  added a layout regression test for both zero-height and visible toolbars.
- Build 89 showed the host identity prompt and LAN credentials dialog after
  reconnecting. The final simulator build passed; all seven focused widget tests
  passed. The simulator exercised the real iOS keyboard in the login dialog.
- At build 89, remote-session keyboard and chat acceptance were pending authentication.
  The attempt to reuse the existing host credential is waiting for macOS
  Keychain confirmation, which the automation tool cannot operate. Do not count
  the login keyboard as proof that the remote keyboard works in landscape.

Evidence: `/tmp/landesk-sim89-evidence/before-black-screen.png` and
`/tmp/landesk-sim89-evidence/after-login-visible.png`.
Logs: `/tmp/landesk-sim88-rust.log`, `/tmp/landesk-sim89-final.log`,
`/tmp/landesk-input89-tests.log`. The physical-device archive 88 predates this
additional mask fix and must be rebuilt before physical-device acceptance.

## Authenticated simulator follow-up (builds 90–92)

The user approved reuse of the existing host credential. Authentication to the
Mac succeeded; no password was printed or written to test artifacts.

The live session exposed two additional failures:

- Chat taps threw `NavigationBar is not a subtype of BottomNavigationBar`.
  Chat now checks the home page's actual chat-tab state, only for incoming
  sessions, rather than casting the navigation widget or hardcoding tab 1.
- Adding the physical-key wrapper after authentication remounted the owner of
  the keyed Overlay. The reused Overlay lost its underlying entry: the remote
  image went white and the remote input field disappeared. Keeping the session
  overlay outside that changing wrapper restored both the image and keyboard.

Build 91 on iPhone 17 Pro / iOS 26.5 demonstrated the remote Mac image, landscape
software-keyboard opening, keyboard retention across portrait/landscape rotation,
and closing the keyboard. Chat opened and closed. This was a real authenticated
session, not the connection form or a widget-only harness.

Landscape chat then exposed a fixed-height window whose input was behind the
keyboard. Build 92 constrains the iOS chat window to the actual overlay space,
clamps its displayed position to the safe area, and preserves the saved position
while resizing. Simulator verification showed both close and input controls above
the keyboard, and entering `landesk test` populated the chat draft.

Nine focused widget tests passed, including authentication-wrapper transitions
and shrinking/restoring the chat viewport. Targeted analysis has no errors or
warnings (seven existing deprecation infos). Simulator build 92 passed and was
installed. Logs: `/tmp/landesk-input92-tests.log`,
`/tmp/landesk-input92-analyze.log`, `/tmp/landesk-sim92-build.log`.

Evidence: `/tmp/landesk-sim91-evidence/landscape-keyboard.png`,
`/tmp/landesk-sim92-evidence/landscape-chat-input.png`.

Remaining acceptance: the host became locked during testing. Build 92 reconnect
authenticated but waited for its first screen frame. Actual remote text entry,
chat delivery/reply, voice audio, and physical iPhone acceptance are not verified.
The landscape chat input remains narrower than desirable because its content
also applies safe-area padding; this is a remaining presentation issue.

After the user unlocked the Mac, build 92 reconnected and displayed the live
desktop again. Landscape software keyboard opening was rechecked. The simulator
submitted the test chat message `LAN92-1048` and displayed its outgoing bubble;
Mac receipt/reply is still unconfirmed because querying the installed Mac app
through the desktop UI tool timed out. A blank TextEdit document was prepared,
but the host foreground continued switching between the user's working apps.
No remote test text was sent to those apps; input acceptance waits for the user
to leave the blank test document in front briefly.

## Remote text delivery verified (build 92, 12:18 follow-up)

With the user keeping the blank TextEdit document in front, Midscene/WDA entered
`landesk landscape 92` through the simulator's active remote software keyboard.
The remote image showed the text in TextEdit (initial letter capitalized). Tapping
the visible iOS backspace key removed the final `2`. Rotating to portrait retained
the keyboard; entering `2 portrait` restored that digit and appended the suffix.
Rotating back to landscape and entering ` landscape-again` also succeeded.

Independent, read-only Mac accessibility inspection confirmed the final document
value exactly: `Landesk landscape 92 portrait landscape-again`. No Mac-side typing
or paste API was used for these inputs. This verifies actual remote delivery,
backspace, and continued input across both orientation changes in the simulator.
Evidence: `/tmp/landesk-sim92-evidence/remote-text-rotation.png`.

Mac chat UI inspection still timed out (`timeoutReached`), so chat receipt/reply
remains unverified. Physical iPhone and voice acceptance also remain pending.
