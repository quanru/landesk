# Cloud account and NAT traversal audit — 2026-10-27

## Conclusion and scope

No executable cloud-account authentication, rendezvous registration/ID lookup,
STUN/TURN/ICE negotiation, NAT punching or relay fallback was found in the native
Rust/Flutter runtime paths inspected. This conclusion comes from call-path review,
resolved dependencies and tests, not from keyword absence alone.

Retained `LoginRequest` is authentication to the selected remote host. Device
fingerprints are local cryptographic identities, not cloud accounts. The retained
rendezvous protobuf file supplies `ConnType` and LAN `PeerDiscovery` messages;
unused wire-schema definitions do not create registration or punching behavior.
Generic HTTP compatibility functions in ui_interface.rs return a disabled result;
they neither instantiate an HTTP client nor send requests. Audit functions log
locally or are no-ops; they do not upload events.

## Reviewed paths

| Path | Behavior |
| --- | --- |
| src/client.rs, Client::start | Requires a private numeric IP. Tries the requested endpoint and locally discovered addresses; failure ends with an error. |
| libs/hbb_common/src/tcp.rs, FramedStream::new | Now validates the numeric private endpoint before resolution/socket creation. No outbound DNS lookup, proxy or public-address fallback. |
| src/server.rs / src/lan_server.rs | Starts LAN listeners. Rejects public source IPs, including public IPv4-mapped IPv6, before creating sessions. |
| src/lan.rs / src/lan_mdns.rs | LAN UDP discovery/mDNS only. Public interfaces and public discovery responses are filtered. |
| src/server/connection.rs | Remote-host credential authentication; tunnel targets now require a private numeric IP (localhost maps directly to 127.0.0.1). |
| src/port_forward.rs | Client-side forwarding listener binds to 127.0.0.1. |
| src/web_gateway.rs / web/src/main.ts | Local HTTPS/WebSocket gateway, source/authority checks and same-origin browser requests. No external signaling service. |
| libs/hbb_common/src/config.rs | Old cloud/transport fields and cache types removed. Both main and local option paths reject retired settings/tokens. |
| Cargo.lock | No resolved webrtc, stun, turn, natpmp, igd or reqwest package. TLS, crypto and built-in media capture dependencies remain. |
| Native Swift/Kotlin wrappers | No additional cloud-account or NAT traversal networking entrypoint found. |

## Findings fixed

1. Unused cloud address book/device group cache code still defined access-token
   storage and loaders. Removed those types, serializers and file-loading code.
2. Private-IP validation previously depended on the desktop session caller.
   Enforced it in the low-level TCP constructor before any resolver/socket call.
3. Authenticated port forwarding could connect to a public IP or hostname. It now
   rejects those targets. Localhost and private/Tailscale IPv4/ULA IPv6 remain valid.
4. Removed persisted rendezvous/NAT/proxy fields and obsolete config-key exports;
   old config input cannot restore them. Local preferences now reject retired
   tokens and traversal options too.
5. Removed two UDP route-selection probes to 192.0.2.1. Those did not send payloads
   or perform STUN, but were unnecessary in a private-interface-only implementation.
6. Removed the disabled WebRTC echo example and stale traversal logger settings.

## Verification

- hbb_common full unit suite: 99 passed, including private egress rejection,
  real loopback TCP connection, forwarding destination policy and old-config migration.
- Native release tests matching lan_: 24 passed, covering local server, handshake,
  discovery metadata and web-gateway policy.
- Native LAN discovery/address selection tests: 7 passed.
- Mac arm64 release build, signature verification, installation and GUI launch passed.
- Six startup socket snapshots showed no established public TCP connection. UDP
  sockets, mDNS and a transient TCP listener were present; this does not establish
  the destination of every UDP packet.
- LAN-only residual check now covers cloud cache types, traversal options and
  forbidden packages in Cargo.lock as well as runtime symbols and UI entrypoints.

## Evidence limits

An administrator packet capture was not available: `sudo -n tcpdump -D` reported
that a password was required. Socket snapshots cannot rule out brief connections.
Cross-platform real-device connection regression is still separate from the Mac
build and local tests. Tailscale's own networking/DERP routing and OS certificate
services are outside LocalDesk's source and cannot be controlled by this cleanup.
