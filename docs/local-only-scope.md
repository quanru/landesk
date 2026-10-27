# Local-only product scope

landesk has no cloud sign-in, registration, cloud address book/device sync,
rendezvous/ID server, NAT punching or relay fallback. Public IP endpoints are
rejected. Tailscale private addresses remain supported.

Removed from source, rather than hidden:
- Native account management UI, Rust identity CRUD/keychain manager, session
  identity lookup/default binding, shared identity configuration fields and FFI.
- Online updater and downloadable plugin modules, startup/IPC/session hooks,
  bridge methods, Cargo feature declarations and direct HTTP/update dependencies.
- The obsolete Sciter frontend, which contained cloud login and public-server
  configuration. Desktop builds require the Flutter feature.
- Update manifest generation/publishing and legacy Web account bridge methods.

Keep these local functions:
- LAN/private-VPN direct IP connections and LAN discovery.
- Remote-host username/password authentication and fingerprint verification.
- Credentials remembered per host, local recents/favorites and virtual-key layouts.
- Remote desktop, input, clipboard, files, terminal and the LAN web gateway.
- Built-in Flutter rendering/native integration plugins (not downloaded plugins).

Generated Rust/Dart/C bridges must be regenerated from src/flutter_ffi.rs before
building; the removed account/updater/plugin methods are no longer generated.
The lockfile can retain TLS dependencies needed by local encrypted transports;
a dependency name alone is not evidence of an online service.

Existing retired account metadata is ignored and omitted on the next config save.
The application no longer reads the retired account keychain namespace. This
source cleanup does not delete credentials already stored in the OS keychain.
Per-host remembered credentials remain supported.

The residual check scans implementations, manifest and generated bridge symbols,
not just UI entrypoints. Old protocol definitions, translation labels and
configuration rejection rules can still name retired features without implementing
them. This is not an exhaustive packet-capture proof. Tailscale's own networking
and Apple platform certificate verification are outside landesk.

The transport constructor and authenticated forwarding destinations enforce the
private-IP policy before connecting. Cloud address-book/group token storage and
retired NAT/proxy config fields are removed. See validation/network-path-audit-2026-10-27.md
for the call-path audit, test evidence and packet-capture limits.
