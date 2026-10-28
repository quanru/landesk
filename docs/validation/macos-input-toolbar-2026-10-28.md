# macOS form focus and compact toolbar

## Changes

- CustomAlertDialog now lets FocusScope own its persistent node instead of
  allocating a new node and scheduling a focus request on each build.
- PasswordWidget forwards autoFocus to its TextField; previously false was
  ignored by the shared field. Shared dialog fields disable autocorrection and
  suggestions, avoiding credential edits by text services.
- Desktop connection toolbar: 56 pt row (previously 72), 32 pt controls
  (previously 44 or larger), 16–18 pt icons, 13 pt labels and 8 pt gaps.
  Light/dark semantic colors and tooltips remain in use.

## Validation

- Focus regression: old CustomAlertDialog fails the scope-identity assertion
  after a rebuild; fixed implementation retains the active field, its scope,
  and composing text. This is a focus lifecycle regression test, not a measured
  end-to-end latency benchmark.
- Three widget tests pass: focus regression and connection form in both themes.
- Targeted analysis has no errors; existing deprecations and an unused `direct`
  variable in dialog.dart remain.
- macOS release build succeeds. Certificate-backed installer verifies the
  previous designated requirement and installs to /Applications/LocalDesk.app.
- Live verification is blocked: CUA repeatedly times out obtaining the app's
  window, including after resetting its session and removing duplicate GUI/tray
  processes. The GUI main-thread sample is predominantly idle. Before updating,
  an existing remote session was waiting for video and GUI/server CPU snapshots
  were 76%/61%; this is not enough evidence to attribute typing delay to CPU.

Physical keyboard/IME latency and visual inspection of the installed toolbar
remain pending. Do not report all input lag as resolved from widget tests alone.
