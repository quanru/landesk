# landesk minimal theme

All Flutter clients and windows use `LandeskTheme` through `MyTheme`. The existing system/light/dark preference and its persistence remain unchanged. The shared implementation covers Android, iOS/iPadOS, macOS, Windows, Linux and Flutter web; platform configuration tests are not native runtime acceptance.

The visual reference is vibelet's **minimal / 素雅** theme. Selected reference files were inspected using GitHub's contents API; studio was not cloned, fetched or pulled. No studio source package is vendored or required at build time.

## Design contract

- Light: white canvas/cards, `#f5f6f8` inset surfaces, `#141414` text, `#2f7a4b` accent.
- Dark: `#181818` canvas, `#222222` cards, `#2a2a2a` inset surfaces, `#ececec` text, `#5bb575` accent.
- Thin neutral borders; control radius 14, card radius 20; restrained elevation and 150 ms feedback.
- Shared buttons, fields, cards, dialogs, bottom sheets, menus, navigation, tabs, chips, selection controls, tooltips, scrollbars and progress indicators.
- Native Flutter button semantics supply keyboard activation, focus and disabled/hover/pressed states. Mobile button targets are at least 44 logical pixels; desktop buttons are 40.
- Legacy custom buttons, tab strips, host/peer cards and navigation use the same tokens. Remote controls and virtual keys follow brightness while preserving circular keys, multi-touch press/release and drag-wheel input.
- Semantic warnings/errors and the remote framebuffer retain their meaning/content. System-owned permission dialogs and window decorations follow the host OS.

Prefer `Theme.of(context).colorScheme` or `SuyaPalette.of(context)` over fixed colors in new widgets. Avoid creating an independent `ThemeData` inside individual pages.

## Validation

From `flutter/`, with Flutter 3.44.1:

```sh
flutter test test/landesk_theme_test.dart test/landesk_theme_preview_test.dart test/mobile test/platform_font_fallback_test.dart
flutter analyze --no-pub lib test/landesk_theme_test.dart test/landesk_theme_preview_test.dart
```

The tests cover light/dark contrast, controls on all six Flutter target-platform configurations, field entry, button activation, dialogs, focused/disabled states and the existing virtual-key/mouse regressions. Optional component-layout PNGs can be generated with `LANDESK_THEME_PREVIEW_DIR=/tmp/landesk-theme-preview flutter test test/landesk_theme_preview_test.dart`; Flutter's default test font is a block font, not production typography.

Native build and device evidence is recorded separately in `docs/validation/suya-theme-2026-10-27.md`.
