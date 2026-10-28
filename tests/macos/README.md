# macOS resolution regression

Run from the repository root on a Mac with Xcode command-line tools:

```sh
clang++ -std=c++17 tests/macos/resolution_modes.mm \
  -framework AppKit -framework AVFoundation -framework IOKit \
  -framework Security -framework CoreGraphics -o /tmp/landesk-resolution-test
/tmp/landesk-resolution-test
```

This test includes the production Objective-C++ source and replaces only its
CoreGraphics display-mode calls with a fake 4K/HiDPI display. It changes no real
screen. It catches logical-pixel confusion in enumeration, current mode and
selection, and checks restoration selection, unsupported requests and transaction
cancellation after configuration failure.

For live verification, compile the real implementation:

```sh
clang++ -std=c++17 tests/macos/resolution_live.mm src/platform/macos.mm \
  -framework AppKit -framework AVFoundation -framework IOKit \
  -framework Security -framework CoreGraphics -o /tmp/landesk-resolution-live
/tmp/landesk-resolution-live
# Requires an unlocked, awake display supporting 1080p. Temporarily changes it:
/tmp/landesk-resolution-live --switch-and-restore
```

The no-argument probe only reads dimensions. The opt-in switch tests the real
1920x1080 request and restores the exact initial display mode on the normal
success/failure path. A killed process cannot guarantee restoration. Neither
probe substitutes for a connected client's decoded-frame dimension check.
