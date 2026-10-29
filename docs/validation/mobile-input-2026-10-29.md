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

## Desktop chat receiver follow-up (build 93)

The installed Mac ran its connection manager as `--cm-no-ui`. Source inspection
showed every desktop session was forced into that mode. Incoming chat forwards
to the CM process, whose Flutter handler requires an `APP_TYPE_CM` event stream;
the no-UI process never creates that Flutter UI. This prevents the desktop user
from seeing and replying to messages, independently of the mobile bubble fix.

Desktop sessions now launch `--cm`; the existing Linux headless path retains
`--cm-no-ui`. This restores the existing session UI and chat/voice controls,
without changing authentication, peer transport, or private-address restrictions.
An ordinary incoming session may show the connection manager window again.

The focused Rust regression test passed (1 passed), and the Mac Rust release
library/service build passed. Logs: `/tmp/landesk-cm93-test.log` and
`/tmp/landesk-cm93-build.log`. The local dependency setup needed an installed-root
mapping for magnum-opus: `/tmp/landesk-host-vcpkg93/installed` points to the existing
`.toolchains/rustdesk-device-deps` directory. No dependency versions changed.

Mac Flutter release build 93 passed and was installed with the existing signing
identity; the installer verified compatibility with the previous designated
requirement and left TCC settings unchanged. The restarted host listens on TCP
21118. Logs: `/tmp/landesk-cm93-flutter.log`, `/tmp/landesk-cm93-install.log`.
The simulator observed the Mac lock screen before installation, then disconnected
during the host restart. A fresh connection reached the LAN credential form.
Desktop chat display/reply still requires an unlocked, authenticated session;
this follow-up does not claim end-to-end chat or voice acceptance.

After the user unlocked the Mac, the simulator authenticated and displayed the
desktop with the new CM window. The running process uses `--cm`. Sending
`LAN93 ping` from the mobile chat at 13:09 displayed that text in the Mac chat
window, visible in the remote image after closing the mobile overlay. This
confirms client-to-host message delivery and display with Mac build 93.
The desktop UI tool now reads the main app, but cannot select the separate CM
process window. Host-to-client reply acceptance is waiting for a manual
`LAN93 pong` reply; no reply has yet appeared in the simulator.

## Bidirectional chat and Mac frame follow-up (build 94)

At 14:10 the simulator displayed the user's Mac reply `LAN93 pong` (14:08),
confirming the reverse direction as well. Evidence is stored locally at
`/tmp/landesk-cm94-evidence/bidirectional-chat.png`; it includes private desktop
content and must not be published with the repository.

The user supplied a close-up of black lines around the Mac CM window. The CM
still requested a transparent native background and drew an additional Flutter
border. It now uses the same native-background policy as the main Mac window,
and leaves macOS frame/corner rendering to AppKit. Other platform borders remain.

Targeted Dart analysis completed with no errors or warnings (9 deprecation
infos). Mac release build 94 and same-identity installation passed. A fresh
authenticated simulator connection displayed the desktop; `LAN94 border check`
was received in the Mac window. Its visible right and bottom edges/corners no
longer showed the hard black lines, but the mobile overlay obscured the left
edge and the user switched foreground apps before a full close-up was obtained.
All-edge close-up and dark appearance checks remain pending. Logs:
`/tmp/landesk-cm94-analyze.log`, `/tmp/landesk-cm94-flutter.log`,
`/tmp/landesk-cm94-install.log`.

## Mac build 95: neutral connection-manager and chat styling

- Replaced the colored initial avatar (the white I in an orange tile was the device-name initial, not a relay indicator) with a neutral devices glyph. Preserved supplied avatars.
- Reduced avatar/name sizing, made long peer IDs ellipsize with a full-ID tooltip, and replaced the low-contrast chat asset with a themed outlined icon and tooltip.
- Shared chat bubbles, timestamps, input borders and send icon now use semantic theme colors. CM controls use neutral surfaces; disconnect retains an error-colored label.
- Targeted Dart analysis passed with no errors or warnings (three existing infos). macOS release build 95 and guarded installation passed using the existing signing identity.
- Simulator build 92 reconnected to Mac 95. Sent `LAN95 neutral theme`; Mac displayed the message. Landscape screenshot confirmed neutral device card, incoming bubble, input and disconnect control with rounded window edges.
- Dark appearance, outgoing bubble appearance and mobile installation of the shared styling have not been visually verified in this round. Simulator remains build 92.

## Build 97: remaining neutral-theme surfaces

- Updated device autocomplete, mobile remote/camera monitor selection, desktop monitor icons, readiness dialog, Android incoming-session avatars/service controls, and TCP/RDP listening banner to semantic neutral theme colors. Selected monitor colors now use paired primary/onPrimary values.
- On simulator 96, dark chat exposed a pale title bar with white text. Fixed the shared mobile overlay header to surfaceContainerHighest/onSurface with a smaller title; simulator 97 visually confirmed the correction.
- Targeted analysis passed without errors/warnings; existing informational diagnostics remain. macOS release 97 and iOS simulator debug 97 built successfully. An intermediate macOS attempt failed with a generated FlutterFramework package-product error; a separate rebuild succeeded.
- Installed simulator 97. Verified light/dark settings and connection UI on build 96, and authenticated simulator 97 to Mac 96, opening the corrected dark chat header/input. Final Mac 97 uses the existing guarded installer/signing identity.
- Not visually accepted this round: multi-monitor selection (no multi-monitor peer exercised), Android controlled-device UI, device autocomplete popup, desktop readiness dialog, TCP/RDP banner, and all hover/disabled states. Desktop CUA app binding timed out. Physical iPhone/iPad and Android builds were not installed.
