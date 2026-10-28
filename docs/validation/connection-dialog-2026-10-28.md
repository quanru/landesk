# Desktop connection dialog fix — 2026-10-28

The submitted screenshot shows the grey `192.168.1.2` placeholder, not an entered
endpoint. The existing blank-address guard returns a generic address/username/
password toast, so no connection attempt is made and the missing field is unclear.
The expanded credentials form also exceeds the dialog content area at 800x510.

The dialog is now a separately testable `LanConnectDialog` with scrollable content
and fixed actions. Its IP placeholder is `IP / IP:port`; blank addresses produce an
inline `Invalid IP` message. Missing usernames with explicit passwords get an
inline username error. Submission reads the visible endpoint controller directly,
rather than a separately synchronized ID value. Remember-password state is passed
to the existing credential payload on submission; transient passwords are cleared
when collapsing credentials or closing the dialog. Native authentication is unchanged.

## Verification

- At 800x510, disabling scrolling reproduces a bottom RenderFlex overflow of 46px
  in both themes. The fixed form passes the same tests.
- Widget tests click the remember checkbox after scrolling, verify its selected
  state, verify blank IP blocks submission, enter a real endpoint, and verify one
  submission carrying the endpoint and remember=true.
- 21 tests pass across connection dialog, session feedback and theme components.
- Targeted Flutter analyzer: no issues. macOS release build passed.
- Installed at `/Applications/LocalDesk.app`, preserving existing executable name,
  bundle ID and ad-hoc signing mode. Strict deep signature verification passed and
  installed App.framework matches the build. Only the main GUI was restarted;
  the existing host listener remains on TCP 21118.
- Post-install native UI automation timed out; GUI click verification and an
  authenticated remote session have not been claimed. Tests verify form submission,
  not successful authentication or persistence after host login.

Logs: `/tmp/landesk-login-nonscroll-regression.log`,
`/tmp/landesk-login-final-tests.log`, `/tmp/landesk-login-analyze.log`,
`/tmp/landesk-login-build.log`.
