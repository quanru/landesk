# Installed macOS icon refresh

Updated `/Applications/LocalDesk.app` with the committed landesk cartoon icon:

- `Contents/Resources/AppIcon.icns`
- `Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/icon.png`
- `Contents/Frameworks/App.framework/Versions/A/Resources/flutter_assets/assets/icon.svg`

The installed ICNS SHA-256 matches the generated repository asset:
`9b9746d1315b1aa5fe9d2f0789e23e93ee96029ea95a8fbfd9158eabcb08fc19`.
The nested App framework and application were re-signed with the existing ad-hoc
signing mode, and `codesign --verify --deep --strict` passed. Launch Services
registration was refreshed. All 51 repository icon assets passed their check.

`tools/localdesk/update-macos-icons.sh` reproduces this resource-only update and
rejects installations with a non-ad-hoc signature. It preserves the executable,
installed bundle path, existing launchd paths and app data; this is not a full
replacement with the latest native code. macOS may re-evaluate permissions after
an ad-hoc signature changes.

The application process was running after the refresh. The computer-use tool
could not capture the application or Finder window (`cgWindowNotFound` /
`timeoutReached`), so a visible Dock/Finder screenshot is not an acceptance result.
