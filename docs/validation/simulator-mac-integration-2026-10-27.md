# LocalDesk iPad simulator / Mac integration

Base revision: 7b894a70f (common library b483302).

## Verified

- Production Rust library built for `aarch64-apple-ios-sim`, with Flutter enabled.
- Production Flutter iOS simulator debug build passed.
- Installed and launched `dev.quanru.localdesk` on iPad mini (A17 Pro), iPadOS 26.5, simulator `6E387569-DB27-4123-9377-A740540BC264`.
- Device Hub visibly displays the LocalDesk connection page. Entered `127.0.0.1` as the Mac connection address.
- Current Mac has the corresponding LocalDesk build installed.

Build logs: `/tmp/localdesk-latest-simulator-rust.log`, `/tmp/localdesk-latest-simulator-flutter.log`. Launch evidence: simctl returned PID 7049. Screenshot: `/tmp/localdesk-ipad-current.png`.

## Pending user setup and session validation

Mac UI reports screen recording permission missing and no local host credentials configured. User must set the host credentials and grant screen recording/accessibility permission; credentials need not be posted in chat. No authenticated remote session has been established in this test.

After setup, connect from the simulator to `127.0.0.1` using the local host credentials. Validate remote picture, single-tap left click, two-finger right click, independent drag wheel, Cmd+Space, Cmd+Tab, custom layouts and persistence. These are pending, not passed. Simulator integration is separate from physical iPad acceptance and performance measurement.

## Rebuild helper

`tools/localdesk/build-ios-simulator.sh [booted-simulator-UDID]` regenerates the bridge and builds the native library and production Flutter client; when given a booted simulator UDID, it also installs and launches the app. Requires Rust 1.82, flutter_rust_bridge_codegen 1.80.1 on PATH, Flutter 3.44.1 via FLUTTER_BIN, simulator vcpkg dependencies via VCPKG_ROOT (and VCPKG_INSTALLED_ROOT if external), and host/simulator libsodium pkgconfig directories via the two target-specific PKG_CONFIG_LIBDIR environment variables documented by the script. The constituent build/install/launch commands were verified individually; the helper itself has only been syntax checked.
