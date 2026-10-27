# Local-only product scope

LocalDesk has no cloud-account sign-in, account registration, cloud address book,
cloud device synchronization, rendezvous/ID server, NAT punching or relay fallback.
The SubnetDesk LAN baseline already removed the cloud account workflows. LocalDesk
also removes updater/plugin UI, startup hooks, HTTP/plugin implementation modules,
and automatic-update manifest publishing. Public IP endpoints are rejected.

Keep these local functions:
- LAN/private-VPN direct IP connections and LAN discovery.
- Per-host username/password and fingerprint verification (not a cloud account).
- Local recents/favorites, per-peer options and virtual-key layouts.
- Remote desktop, input, clipboard, files and terminal over the local connection.

Some generated bridge compatibility methods, disabled feature guards, translations
and legacy non-shipping frontend references remain. They are not working cloud
features: enabling `plugin_framework` or `software-update` fails compilation, and
the implementation modules and native Flutter entrypoints have been removed.
The old Flutter Web/Sciter release paths remain disabled; the separate LAN web
gateway uses local authentication and the same incoming private-IP policy.

`scripts/check_lan_only_residuals.sh` checks removed implementation files, public
transport/config symbols and cloud/plugin/updater entrypoints in the native UI.
It is a regression guard, not an exhaustive network-capture proof. Tailscale's
own networking and Apple platform certificate verification are outside LocalDesk.

The native UI also removes the inherited local identity/account manager: no
account toolbar, add-account dialog, account selector or peer account menu.
Connections still request the remote host credentials and can remember them
per host. Existing stored credentials are not deleted by this UI change.
