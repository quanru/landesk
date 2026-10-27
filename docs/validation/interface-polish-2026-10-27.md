# LanDesk interface refinement — 2026-10-27

## Changes

- The displayed app name is **LanDesk**. Repository names and bundle/storage identities remain unchanged. Flutter normalizes older native display names so reused native archives also display the correct title.
- Tablet landscape uses a navigation rail, a bounded connection form and an adjacent device list. Narrow screens retain a single column and bottom navigation.
- The connection form has persistent labels, normal-size neutral IP text, one field boundary, a primary Connect button, password visibility and quiet secondary actions. Autocomplete, credential entry and direct connection callbacks remain wired to the existing implementation.
- Desktop connection dialogs use the same label hierarchy. Settings content has a readable maximum width.
- Device categories use text labels; device tiles no longer use randomly colored backgrounds. Grid cards no longer have decorative blue gradients. Empty states use a small neutral device icon.

## Evidence

- 32 targeted Flutter tests passed (theme/platform configurations, mobile peer layout and virtual-key/mouse regression).
- Flutter library analysis reported no errors; pre-existing warnings/info remain.
- macOS Release and iOS simulator Debug builds passed.
- Branding and generated-icon checks passed, including the Linux service display-name contract.
- iPad mini simulator: installed, launched, and captured real light/dark screenshots. The title is LanDesk; IP text is neutral and legible in both modes; the two-column layout is visible.
- iPhone 16 simulator: installed and launched. Portrait screenshot confirms the single-column form and bottom navigation fit without visible overflow. The final empty-state device icon and subdued hint were captured and inspected.
- These are simulator rendering checks, not physical-device or authenticated remote-session acceptance. No claim of native Windows/Linux/Android runtime testing.
- macOS installed application was not replaced. Native libraries were reused for Flutter theme/layout builds; the Rust display-name literal will take effect on clean native rebuilds, while the Flutter normalization handles existing archives.

Local screenshot paths: `/tmp/landesk-refined-light.png`, `/tmp/landesk-refined-dark.png`, `/tmp/landesk-refined-phone.png`. Local logs: `/tmp/landesk-polish-tests.log`, `/tmp/landesk-polish-analyze.log`, `/tmp/landesk-polish-simulator-final.log`, `/tmp/landesk-polish-macos-final.log`.
