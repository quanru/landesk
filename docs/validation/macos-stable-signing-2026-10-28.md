# Stable macOS signing and capture permission errors

## Evidence

The installed app used an ad-hoc designated requirement tied to its current
`cdhash`. Each changed executable can therefore represent a different identity
for privacy grants, despite a stable bundle ID and path. Apple documents this in
[TN3127](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).
The host log repeatedly reports `Failed to create capturer` after successful
connection. The previous UI also reported missing screen-recording permission.

## Changes

- `sign-macos.py` requires a certificate identity, signs nested code inside out,
  verifies the bundle, and checks a previous certificate-backed designated
  requirement before an update can be installed. No ad-hoc fallback.
- `install-macos.py` stages a symlink-preserving copy, preserves installed bundle
  and executable identity, signs and verifies before touching the installed app,
  then restarts only this user's installed app processes. It does not modify TCC,
  credentials or app data. Ad-hoc-to-certificate migration must be explicit.
- The Mac build helper uses `LANDESK_CODESIGN_IDENTITY` or local Git setting
  `landesk.codesignIdentity`. Icon refresh uses the same guarded installer.
- The desktop host checks screen-capture permission before returning a successful
  login response. Missing permission returns `config_screen` instead of reporting
  success and waiting indefinitely. File, terminal, port-forward and camera
  connections are excluded from this capture-only check.

## Local setup

A valid existing Apple Development certificate was selected and pinned in this
checkout's Git config. This is local development signing, not Developer ID
notarized public distribution. Keep using the same identity for this installation.
Do not overwrite it with an ad-hoc build or alternate certificate class.

```sh
git config landesk.codesignIdentity '<fixed signing identity>'
python3 tools/localdesk/install-macos.py \
  flutter/build/macos/Build/Products/Release/landesk.app
# Only for migration from the previous ad-hoc installation:
# append --migrate-adhoc
```

## Verification so far

- Python compile and shell syntax checks pass.
- Re-signing a certificate-backed app after changing a bundled resource preserves
  the designated requirement and passes `codesign --verify -R` against its old
  identity. Ad-hoc identity `-` is rejected.
- Migrating from the existing ad-hoc app can require one final macOS permission
  grant. No grant is inserted/reset programmatically. Successful capture and
  permission persistence after a real subsequent update require user acceptance
  of that system grant and a connected-session test.

## Installed state

Full Rust release build passed (1m56s). The certificate-backed build was installed
using the new staging installer; strict deep verification passed, and the running
user-session host listens on TCP 21118. Its designated requirement is certificate-
backed instead of a code hash. Existing root launcher process was not restarted.

## Permission refresh and reinstall check

After the user completed system authentication, toggling the old recording entry
was insufficient: the app still reported missing recording permission. Removing
that old entry and adding `/Applications/LocalDesk.app` through System Settings,
then using Quit and Reopen, cleared the recording warning. The old accessibility
entry was also refreshed through System Settings with user participation.

The same release bundle was then installed again with `install-macos.py`, without
`--migrate-adhoc`. The installer verified the previous designated requirement,
restarted the GUI and host, and did not modify TCC. After this reinstall, the app
showed the green desktop Ready state with no recording/accessibility warning;
the user-session host listened on TCP 21118. This verifies permission retention
for this same-build reinstall, not yet a different-code release upgrade.

The iPad simulator remains at the LAN credentials form. Actual video delivery,
input control, saved-credential reconnection and a different-code upgrade remain
unverified until an authenticated connection is available. No password was read
or requested in chat, and this check did not change the host display resolution.
