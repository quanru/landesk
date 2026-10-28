# macOS 1080p resolution fix — 2026-10-28

## Reproduction and cause

On this Mac's DELL U2720Q, the active mode is 1920×1080 logical points backed
by a 3840×2160 framebuffer. The existing MacGetMode returns logical dimensions.
`platform::change_resolution` compares those to the requested dimensions and
returns success immediately for a 1920×1080 request, without changing anything.
Additionally, the old MacSetMode matches logical dimensions and prefers HiDPI,
so bypassing that guard could still select a 3840×2160 framebuffer.

Read-only probe linked to the original production Objective-C++ implementation:

```text
reported=1920x1080 actual=3840x2160 request1920x1080_shortcircuits=YES
candidate logical=1920x1080 pixels=1920x1080 refresh=60.00
candidate logical=1920x1080 pixels=3840x2160 refresh=60.00
```

This is native-path reproduction, not a completed remote-client GUI reproduction.
An attempted direct mode switch while the screen was locked returned false;
that attempt is not evidence of a working display change.

## Fix

- macOS mode enumeration, current-mode reporting and mode selection use framebuffer
  pixel dimensions consistently. HiDPI preference applies only within the requested
  pixel size.
- Server original-resolution metadata and disconnect restoration also use pixel
  dimensions. Mode queries avoid dependence on capture scaling, which may change
  when multiple sessions are active.
- Failed changes do not register a new restoration entry. Failed CoreGraphics
  configuration cancels the pending display transaction.
- No protocol, client-side zoom, LAN access policy or screen capture permissions
  were changed. The fix is in the Mac host; clients need a new connection to receive
  the revised resolution list.

## Verification

- The same regression test compiled with the old production source fails at
  `w == 3840 && h == 2160`; with the fixed source it passes.
- Tests cover mode enumeration, actual-current size, 1080p selection, 4K HiDPI
  restoration selection, unsupported dimensions and failed-transaction cancellation.
- Fixed live read-only probe reports `reported=3840x2160 logical=1920x1080 pixels=3840x2160`.
- Full Rust release build with Flutter and service passed (Rust 1.82, 2m19s).
- Flutter macOS release build passed (61.9 MB); service bundled and ad-hoc signature
  verified with `codesign --verify --deep --strict`. The installed host has not yet
  been replaced.
- Test/probe instructions: [tests/macos/README.md](../../tests/macos/README.md).

Logs on the development Mac: `/tmp/landesk-resolution-before.log`,
`/tmp/landesk-resolution-after.log`, `/tmp/landesk-resolution-rust-build.log`,
`/tmp/landesk-resolution-macos-build.log`.

## Remaining acceptance

The Mac is locked; the user was asked to unlock and wake the display. Do not mark
physical switching or remote decoded-frame dimensions as passed until then.
After unlock:

1. Run the live probe with `--switch-and-restore`, verifying 1920×1080 pixels and
   restoration to the initial mode.
2. Install the rebuilt Mac host using the existing application identity and signing
   approach, then reconnect the iPad/iPhone client.
3. Select 1920×1080 in the actual resolution menu and confirm the host capture log
   and client's decoded picture dimensions both become 1920×1080.
4. Exercise pointer accuracy, restore 3840×2160, disconnect and check restoration.

This change selects supported physical modes. It does not synthesize a new mode
or add virtual monitors for displays lacking 1920×1080 support.
