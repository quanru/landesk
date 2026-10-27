# Virtual keys simulator preview

This is a **component harness, not a RustDesk remote client**. The production
widget and event sender are symlinked from `flutter/lib/mobile/widgets`; no copy
of their implementation is maintained here. A visible event log replaces only
the remote FFI writer. Canvas counters expose unwanted touch propagation.

On Apple Silicon with Xcode, an iOS runtime, CocoaPods and Flutter 3.24.5:

```sh
xcrun simctl list devices available
FLUTTER_BIN=/path/to/flutter/bin/flutter ./run_simulator.sh IPAD_SIMULATOR_UDID
```

The script generates the disposable iOS host project. A local xcconfig selects
arm64 and iOS 15 for Xcode 27 compatibility; it does not change the production
app's deployment target. The installed bundle ID is
`dev.quanru.virtualKeysPreview`.

Tap a key to inspect the sender's complete sequence. Long press a key to edit,
then drag it or tap to configure its key/modifiers. Tap the top-left checkmark
to finish editing. Tap the controller icon to hide/show all keys. Restart the
app to verify persistence. Rotate to check normalized layout coordinates.

Passing these checks proves Flutter interaction and the writer's arguments.
It does not prove Rust bridge linkage, remote host input, clipboard sync,
Tailscale connectivity, iPadOS hardware behavior, or release signing.
