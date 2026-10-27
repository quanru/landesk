# Local-only implementation cleanup — 2026-10-27

## Scope

Removed the local account-profile backend, default/bound identity resolution,
account keychain reader/writer, shared profile metadata and public FFI methods.
Session authentication still accepts explicit per-host credentials and can load
credentials remembered for that host fingerprint. Retired account payload fields
are rejected by the JSON deserializer rather than silently accepted.

Removed updater/plugin feature declarations, HTTP helpers, IPC/session hooks,
bridge methods and direct reqwest/ring dependencies. Removed the obsolete Sciter
frontend and sciter dependency. Built-in Flutter native plugins remain necessary
for rendering/input and are not a plugin download service.

Generated bindings were regenerated with flutter_rust_bridge_codegen 1.80.1.
They are ignored by Git; both iOS and macOS build helpers regenerate them.

## Checks

- Shared configuration tests: 37 passed, including migration from retired account
  metadata while preserving the current endpoint and Flutter layout preferences.
- Shared LAN tests: 5 passed (endpoint policy and credential field validation).
- Flutter mobile tests: 12 passed (keys, layouts, wheel and touch gestures).
- Targeted Flutter analysis: no errors; existing warnings/deprecations remain.
- LAN residual, branding and release-upload-retry source checks passed.
- Generated Rust/Dart/C bindings contain no retired account/updater/plugin APIs.
- Release dylib export inspection: retired APIs absent; per-host LAN login remains exported.

- Final macOS arm64 release build and deep signature verification passed.
- Installed at /Applications/LocalDesk.app; GUI launched and the add-device form opened.

## Limits

This is not a packet-capture audit or a cross-platform remote-session acceptance
run. iPad, Windows and Linux runtime validation remains outstanding. Existing
retired secrets in the OS keychain are not deleted, but no application path reads
the retired account namespace. Local per-host password authentication is retained.
The local Mac build uses software codecs.
