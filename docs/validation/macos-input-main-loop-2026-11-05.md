# macOS input blocked by tray ownership

## Reproduction and cause

On the installed native development build, an independent `LanDesk --tray` held `/tmp/md.lifeos.LanDesk-tray-501.lock` (PID 11218), while `--server` ran as PID 11251. The iPhone displayed the desktop and virtual controls, but input did not operate the Mac.

The tray de-duplication introduced in `75df8b6d4` returned from `make_tray()` whenever another process held the icon lock. For a macOS server, `core_main` starts the server worker and calls `start_tray()` on the main thread before joining that worker. Returning early therefore left the main thread in `JoinHandle::join`, with no AppKit run loop. `handle_mouse`, `handle_pointer` and `handle_key` dispatch work onto that same main queue, so video/networking continued while input could not run.

`sample 11251` confirmed `core_main.rs:410 -> JoinHandle::join -> _pthread_join` on the main thread. A short event-tap check did not observe the controlled Tab events; that absence alone was not used as proof of transport failure.

System Settings showed LanDesk's existing Device control and data access permission enabled. We toggled it off/on, then removed the existing entry and re-added `/Applications/LanDesk.app` through the normal UI. No TCC database was modified. These actions did not visibly restore control before the native fix; permission reauthorization was a concurrent troubleshooting step, so the runtime result is not a permission-isolated experiment.

## Fix and verification

Keep the server's event loop running when another process owns the tray; suppress only icon creation. Duplicate standalone `--tray` processes still return, and an acquired file lock remains held by the event-loop closure.

- Current-source macOS native library and service built successfully; installation passed strict deep signing and previous designated-requirement compatibility checks.
- After installation, the server (PID 32532) was sampled in `tao::EventLoop::run_return` and `CFRunLoop`, rather than joining the server worker on the main thread. In this observed post-install run, the server owned the icon lock; the no-icon server path was compiled and source-reviewed but was not separately confirmed with a second live lock owner.
- The user then confirmed the physical iPhone could operate the Mac.
- Both existing service-migration tests passed. No Windows/Linux/mobile Rust input path was changed.

Local evidence: `/tmp/landesk-input-before-stack.txt`, `/tmp/landesk-input-after-stack.txt`, `/tmp/landesk-input-mainloop-build.log`, `/tmp/landesk-mainloop-install.log`, `/tmp/landesk-service-migration-tests.log`.

Regression surface: `src/tray.rs` changes only the macOS handling of an occupied icon lock and icon initialization. The network protocol, remote authorization and input-permission checks are unchanged. Remaining useful coverage is an isolated live test with an independent tray retaining the lock while the server injects input.
