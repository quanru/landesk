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
  verified with `codesign --verify --deep --strict`. The host was subsequently updated after unlock; see below.
- Test/probe instructions: [tests/macos/README.md](../../tests/macos/README.md).

Logs on the development Mac: `/tmp/landesk-resolution-before.log`,
`/tmp/landesk-resolution-after.log`, `/tmp/landesk-resolution-rust-build.log`,
`/tmp/landesk-resolution-macos-build.log`.

## Post-unlock verification

Actual DELL U2720Q measurement with the fixed native implementation:

```text
before reported=3840x2160 logical=1920x1080 pixels=3840x2160
after reported=1920x1080 logical=1920x1080 pixels=1920x1080
requested1920x1080=PASS
restored reported=3840x2160 logical=1920x1080 pixels=3840x2160
restore=PASS
before reported=3840x2160 logical=1920x1080 pixels=3840x2160
```

Live testing found an additional issue: simply matching pixels while preferring
HiDPI can select a 960x540 logical desktop for a 1920x1080 framebuffer. Selection
now first prefers the current logical layout within the requested pixel size.
The regression display includes this smaller HiDPI candidate before the native
1080p candidate. The final live measurement preserves the 1920x1080 layout.

The live probe now restores via a session-scoped display transaction. Temporary
CGDisplaySetDisplayMode restoration had reverted when the probe exited; this was
caught and corrected, and a separate post-exit read confirms 4K restoration.

The final Rust release build passed. The rebuilt library and service were bundled
into the existing Flutter release app. Installed at `/Applications/LocalDesk.app`,
preserving bundle ID, executable name, app data and ad-hoc signing mode. The first
staging copy lost framework symlinks; it was rebuilt preserving symlinks, reinstalled,
and `codesign --verify --deep --strict` passed. Installed native-library SHA-256
matches the build artifact:
`bc1f3e1621101e8648cfe25bda51eaaf9755592503d907842307617f0d7928ae`.
The GUI and user-session server were restarted; TCP 21118 is listening. The existing
root service process was not restarted (it is not the display capture process).

## Remaining acceptance

The iPad mini simulator reaches the actual LAN credentials dialog on the updated
host. No saved credentials were available; the user was asked to enter credentials
in the simulator, without sharing them in chat. Authentication was not bypassed.

After login, select 1920x1080 in the actual client menu and confirm host capture
and client decoded-frame dimensions, pointer accuracy and disconnect restoration.
These end-to-end checks remain pending; the live native probe is not a substitute.

This change selects supported physical modes. It does not synthesize a new mode
or add virtual monitors for displays lacking 1920×1080 support.
