<p align="center"><img src="assets/brand/landesk.png" alt="LanDesk" width="120"></p>

# LanDesk

An open-source remote desktop for LANs and private networks, based on
[RustDesk](https://github.com/rustdesk/rustdesk), with a modern theme and configurable
virtual keys. Use it with Tailscale when your devices are on different networks.

[Website](https://landesk.lifeos.md/) · [简体中文](README.zh-CN.md) · [License](LICENCE)

## Native RustDesk migration

The `main` branch now uses a fixed official RustDesk baseline. The previous
SubnetDesk-based implementation is preserved on `legacy`. **It is not a released or fully validated
build.** Current implementation and verification results are recorded in
[the migration ledger](docs/validation/native-migration-progress-2026-11-04.md).

- Connect using a numeric private IP address, optionally followed by a port.
  The default native port is `21118`. LAN discovery supplies direct endpoints.
- Keep upstream password authentication, host approval and session permissions.
- Native IP sessions do **not** add application-layer transport encryption.
  Use Tailscale or a VPN when encrypted transport is needed. Ordinary LAN access
  is not automatically encrypted.
- Public device-ID connections, rendezvous, NAT punching, relays, cloud accounts
  and automatic online updates are disabled at product entry points.
- Desktop browser access is optional and uses HTTPS plus the same native password
  and permission checks. Enable it in Network settings; its default port is `18123`.
- Virtual keys support combinations, press/release and editable layouts. Theme
  and input controls are shared across the supported Flutter targets.

Both endpoints need the new version. Old SubnetDesk protocol messages, credentials
and settings are not imported or converted. Old configuration files are left in
place; this branch uses a separate configuration namespace. Interoperability with
other RustDesk builds is not promised without verification.

## Downloads and screenshots

The [website](https://landesk.lifeos.md/) contains the existing downloads and
TestFlight entry. Those builds predate this migration; they are not binaries of
this branch. No new release has been published from this work.

<img src="assets/screenshots/native-ios-connected.png" alt="Native migration development build: iOS simulator controlling a real macOS desktop with virtual keys in landscape" width="880">

<img src="assets/screenshots/native-ios-system-keyboard.png" alt="iOS system keyboard in the native migration development build" width="320">

Captured on 2026-11-05: an iOS simulator connected to a real Mac through the
new native protocol. Virtual C, Enter and V keys reached TextEdit; system-keyboard
text input, portrait/landscape layout and keyboard show/hide were checked. These
are development-build screenshots, not evidence of a new public release.

## Source and build

The fixed application and common-library revisions are in
[the baseline manifest](tools/migration/native-baseline.json). Initialize the
recorded submodule with `git submodule update --init --recursive`.

The local migration environment uses Rust 1.82, Flutter 3.44.1 and
`flutter_rust_bridge_codegen` 1.80.1. Generated bridge files must match
`src/flutter_ffi.rs`. Browser protobufs are generated from
`libs/base/protos/message.proto`; the browser frontend is under `web/`.

For the implementation plan, scope and acceptance criteria, see
[the migration plan](docs/design/rustdesk-migration-plan-2026-11-04.md).
Building or passing unit tests alone does not establish platform or remote-session
support. See the ledger for the actual verification scope.

## Credits

LanDesk is distributed under **AGPL-3.0**. RustDesk supplies the remote desktop,
media, file-transfer and authentication foundation. The previous LanDesk version
used [SubnetDesk](https://github.com/zibo-chen/SubnetDesk)'s LAN implementation;
retained browser gateway and related code preserve that provenance. Switching the
baseline does not erase those contributions or license obligations. LanDesk's
product theme, virtual keys and integration changes remain separately maintained.

This is an independent fork, not an official RustDesk release. Upstream copyright
and license notices are retained in the source.

## Upstream maintenance

See [the upstream sync guide](docs/upstream-sync.md) for the pinned baseline,
Git ancestry, change reports and verification requirements.
