# Shared neutral theme

- Removed selected-item vertical bars from desktop home and settings navigation.
  Selection remains visible via rounded neutral backgrounds and foregrounds.
- Shared light/dark theme uses grayscale action, selection, field and navigation
  tokens; legacy MyTheme accent constants match. Semantic warnings/errors remain.
- Mobile remote and camera session bottom bars use flat theme surfaces and
  contrasting icons. Keyboard helper keys now use themed idle/held colors.
- Removed the mobile server warning gradient and blue floating-mouse feedback.
- Shared BottomAppBar theme covers gesture help and other bottom bars.

Validation:
- 23 existing theme/virtual-mouse/custom-key tests pass, plus 2 theme preview tests.
- Targeted analysis has no errors; existing deprecation/info findings remain.
- macOS release and iOS 1.3.0 (77) unsigned archive build successfully.
- Windows/Linux/Android receive the shared code but were not built or device-tested.
- Physical iPhone is unavailable; TestFlight upload for build 77 is in progress.
- Live desktop screenshot access has previously timed out; component previews
  are not full product screenshots. No claim of all-screen visual acceptance.
