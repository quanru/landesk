# macOS application name migration

The previous installer preserved `/Applications/LocalDesk.app` and its executable
name even though the display name had changed to LanDesk.

The installer now targets `/Applications/LanDesk.app` with executable `LanDesk`.
Existing legacy installs must first run `tools/localdesk/migrate-macos-name.py`
as the normal user to prepare a signed replacement. Then run the same script
with `sudo /usr/bin/python3 ... --apply <prepared-app-path>` to update the system
launch jobs and remove the old application. The script checks signature identity
compatibility and restores the old launch job contents if activation fails.

Bundle ID, launch job labels, configuration directories and credential identities
remain unchanged. No TCC reset is performed.

## Observed on this Mac

- Installed version: 1.3.0 (98).
- `/Applications/LanDesk.app` exists; `/Applications/LocalDesk.app` no longer exists.
- Bundle name, display name and executable name are all `LanDesk`.
- `codesign --verify --deep --strict` passes.
- User server and system service are running with the new application paths.
- The `LanDesk` server listens on TCP 21118.
- Python syntax checks and launch-plist transformation checks passed before migration.

The UI automation tool timed out reading the application window. Main-window
appearance, retained capture/input authorization and a fresh iPhone connection
have not been revalidated after this migration. A listening socket alone does
not establish end-to-end remote-control success.
