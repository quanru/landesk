# Responsive streaming without changing the Mac desktop — 2026-10-28

## Behavior

- New connections default to Low (Optimize reaction time) quality and 30 FPS.
  Custom-quality fallback is 25 (encoder ratio 0.5), previously 100 (ratio 2).
  Existing explicitly saved quality/FPS settings remain intact.
- Restore adaptive bitrate for encoders supporting quality changes. LAN/VPN
  addressing does not imply uncongested transport. Congestion lowers quality;
  recovery is bounded by the selected quality. The default frame budget stays 30.
- Mac capture defaults to logical desktop dimensions using the existing
  CGDisplayStream output-size parameters. A 1920x1080 logical HiDPI desktop
  backed by a 3840x2160 framebuffer can therefore produce a 1920x1080 stream
  without changing the physical display mode or window layout.
- This is not a universal 1080p cap: output follows logical desktop size, and
  non-HiDPI screens are not additionally downscaled. The advanced host option
  `enable-retina=Y` restores full Retina capture when fewer than two video
  services are active. It requires reconnecting and has no new UI control.
- Updated clients do not automatically reapply saved physical resolutions on
  reconnect or monitor switch to a Mac. Manual resolution changes remain physical mode changes.
  Old clients can still send their saved physical-resolution request; update
  the client as well to get the reconnect behavior.
- No protocol, relay, authentication, display-mode implementation, or TCC
  permissions are changed by this patch.

## Validation

- Five VideoQoS tests passed, including congestion/recovery, quality ceiling,
  non-adaptive encoders and client FPS limits.
- Logical-capture pointer/wheel regression and existing Retina coordinate
  regression passed (two tests).
- Two common-config tests passed: responsive defaults and preservation of
  explicit saved quality/FPS.
- Flutter analysis of changed constants passed.
- Production read-only capture geometry probe: `capture=1920x1080
  coordinate_scale=1`.
- Native physical-mode readback before and after that probe: logical
  1920x1080, framebuffer 3840x2160. No display-mode switch was performed.

Unit tests and geometry probes are not latency measurements or proof of
received video frame dimensions.

## Reproduction / follow-up

Use the same client, network, content and 30 FPS cap for before/after comparisons.
Check host capture dimensions, client decoded dimensions, codec and bitrate;
measure input-to-visible-response latency under scrolling and network contention.
Also verify pointer accuracy at all four corners, scrolling, reconnect and
multiple displays. Do not switch the host physical resolution for this test.

A read-only capture geometry probe is provided at
`libs/scrap/examples/capture_dimensions.rs` (`cargo run --release -p scrap
--example capture_dimensions`, with the native build dependency environment).
It reports production capture geometry but does not start a screen capture or
prove end-to-end video reception.

## Build and installation

- Final Rust release library and service build passed (1m49s incremental).
- Flutter macOS release build 85 passed. Final native library and service were
  copied into the bundle before signing/installing.
- Installed `/Applications/LocalDesk.app` with the pinned Apple Development
  identity; designated requirement compatibility and strict signature checks
  passed. Installed CFBundleVersion read back as 85; TCP 21118 is listening.
- After installation, physical display readback is still 3840x2160 pixels with
  1920x1080 logical layout.
- Shared configuration commit: `landesk-common` `262dd76`.
- iOS/Android/Windows/Linux packages were not rebuilt or installed this round.
  Existing mobile clients therefore still have the old reconnect behavior.
- Remote decoded-frame dimensions, end-to-end latency/bitrate comparisons and
  multi-monitor live interaction remain unverified. Choose Optimize reaction
  time for an existing peer that saved the former 100% custom profile.

Local logs: `/tmp/landesk-responsive-{test,pointer,retina,defaults,capture,display,
flutter-analyze,build-final,macos,install}.log`.
