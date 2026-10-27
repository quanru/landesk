# LocalDesk development build

LocalDesk is an independent RustDesk fork, based on the existing iPad virtual-key
branch. Source: https://github.com/quanru/localdesk, branch
`feat/localdesk-direct-only`. The AGPL-3.0 license and upstream attribution remain.

## Connection policy

- Only literal private IP endpoints are accepted: RFC1918 IPv4, loopback,
  link-local, CGNAT (including Tailscale), IPv6 ULA/link-local/loopback, and private
  IPv4-mapped IPv6. Optional explicit TCP ports are accepted; default 21118.
- Device IDs, DNS hostnames, public IPs, invalid ports are rejected before dialing.
- The Rust client dials a literal socket directly, bypassing SOCKS and WebSocket.
  Failure is returned without ID resolution, hole punching, relay or TURN fallback.
- Desktop/Android host startup runs only the direct listener. Direct IP Access
  still must be enabled explicitly; existing authentication, permission and
  stop-service controls are preserved. Public-source incoming peers are rejected.
- Rendezvous/NAT/IPv6 probes, central online queries, automatic version checks and
  server heartbeat startup are disabled. Mobile account/address-book/group and
  network configuration panels are hidden.
- The policy is compiled into this fork, not a preference. Upstream implementation
  remains in source to minimize the patch; no claim is made that all unused relay
  types or dependencies have been physically removed from the repository.

This is not a network firewall. A VPN may relay underneath LocalDesk, and a peer
can route other traffic on its own. Using an unmodified RustDesk Mac/Linux host
means that host may still contact its configured servers. Installing this iPad
client alone does not change the host's behavior. Removing RustDesk relay fallback
does not fix packet loss, sleep, server crashes or iPad suspension.

## Build

Use Rust 1.81.0, Flutter 3.24.5, and the device dependencies from the existing
RustDesk iOS build. Initialize submodules. Set PATH to the Rust toolchain, set
FLUTTER_BIN, VCPKG_ROOT (with installed/arm64-ios), and separate device/host
libsodium pkg-config directories as required by `tools/localdesk/build-ios.sh`.
The local toolchain had `VCPKG_INSTALLED_ROOT` set to the device dependency root.

```sh
sh tools/localdesk/build-ios.sh
python3 tools/localdesk/sign-ios.py --identity '<Apple Development identity>' \
  --profile '/path/to/profile.mobileprovision'
xcrun devicectl device install app --device '<device-id>' \
  flutter/build/ios/iphoneos/Runner.app
```

The profile must authorize `dev.quanru.localdesk` and the destination device.
The local development signing helper uses the selected profile's entitlements;
production distribution needs its own matching capabilities/profile. Do not commit
profiles or private keys. The new bundle installs separately from RustDesk Keys;
its layouts and saved connections start fresh.

## Checks and limits

- Two standalone Rust policy tests pass (allowed endpoints and forbidden inputs).
- iOS ARM64 Rust release library compiled successfully with flutter + hwcodec.
- Seven existing shortcut/layout Flutter tests pass.
- Targeted Flutter analysis: only two existing WillPopScope deprecation notices.
- Full iOS package signing/build results are recorded locally in artifacts/virtual-keys.
- No packet capture has yet established absence of all unintended network traffic.
- Remote-session stability, Mac/Linux host builds and their runtime policy are not
  yet verified. iPadOS lifecycle bridging and other prior limitations remain in
  `ipad-virtual-keys.md`.

Regression surface: client connection selection and online queries (`client.rs`),
background probes/update checks (`common.rs`), host startup and accepted source IPs
(`rendezvous_mediator.rs`), server heartbeat creation (`hbbs_http/sync.rs`), account
capabilities (`flutter_ffi.rs`), and iOS identity/mobile home/settings. These are
necessary to enforce and expose the direct-only product. Remote input, capture,
authentication and wire framing are unchanged by the direct-only patch; the
existing virtual-key and scene-lifecycle changes are retained from prior work.

## Related projects (reviewed 2026-10-27)

- https://github.com/zibo-chen/SubnetDesk: LAN/VPN fork, no public ID/rendezvous/relay;
  documented releases cover Windows, macOS, Linux and Android, not iOS.
- https://github.com/xyz99002/rustdesk-direct-ip: documents removing registration
  and relay participation; desktop-oriented local/remote roles.
- https://github.com/tyaro/rustdesk-lan: LAN-only fork with Windows/Android assets
  in its latest release when checked.

No code from these forks has been copied into this initial patch. Their stated
capabilities are not a substitute for a source audit or our iPad acceptance tests.
