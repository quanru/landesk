# Neutral desktop backgrounds

- Explicitly map legacy ColorScheme background/onBackground to the neutral
  palette. Desktop pages using those fields no longer inherit seed-tinted colors.
- Replace desktop title-bar, incoming-session header, and installation/help card
  gradients with neutral theme surfaces. Adapt foregrounds for light/dark contrast.
- Keep existing action and status accent colors.

Validation: 14 existing theme tests and 2 component preview tests pass. Targeted
analysis has no errors (deprecation/info findings remain). macOS release build
passes and is installed at /Applications/LocalDesk.app with matching certificate
identity verified. The installer restarted the GUI and user-session server.

Component previews confirm neutral light/dark surfaces, but use the test font.
Live window capture timed out; full installed-UI visual acceptance is pending.
The earlier GitHub release ZIP and iOS TestFlight build are not updated by this change.
