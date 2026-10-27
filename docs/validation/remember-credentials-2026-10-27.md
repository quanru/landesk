# Remembered LAN credentials: peer-refresh regression

The OS Keychain password was paired with a username stored in a synthetic
`PeerConfig` record named `lan-credential-<fingerprint>`. It had no platform
metadata. `PeerConfig::batch_peers` deletes records whose platform is empty,
so refreshing recent devices removed the username required by the login loader.

The fix stores username-only metadata under the separate `lan-credentials`
configuration directory. Passwords remain in the OS Keychain under the existing
service and fingerprint-bound account. Saves now propagate metadata write
failures instead of relying on the peer store's log-only result.

The loader supports old peer metadata and can recover the username from recent
successful connections to the same device fingerprint. Recovered metadata is
persisted only after a valid Keychain password is retrieved. Forgetting a
credential removes both the new metadata and the legacy record.

Verified: the isolated Rust regression calls the real peer loader, reproduces
old metadata deletion, then confirms the new metadata survives repeated refresh
and a fresh disk read. It passed (1 test; 141 filtered out). The subprocess uses a
unique configuration directory and never calls the OS Keychain. The LAN-only
residual check also passed.

Log: `/tmp/landesk-credential-regression.log`.

This is filesystem and code-path evidence, not iPhone restart/authentication
acceptance. The phone was unavailable during investigation; real-device
remember/restart/reconnect behavior remains to be checked after installation.
