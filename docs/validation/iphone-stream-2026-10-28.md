# iPhone streaming experiment — 2026-10-28

## Preparation verified

- Connected physical device: iPhone 15 Pro.
- Latest Rust iOS library rebuilt with flutter,hwcodec; release build passed.
- Flutter iOS archive build 85 passed; signed with the existing Apple Development
  identity and a profile containing this phone. Strict codesign validation passed.
- devicectl confirmed installation of dev.quanru.localdesk. No app data was erased.
- Reusable workload: tools/localdesk/stream-benchmark.html. It provides a fixed
  60-second animation, click counter, input field and scroll list; it performs no
  network requests and is not itself a latency measurement tool.

## Current blocker

The iPhone Use runner built and launched, but XCTest initialization failed:
`Timed out while enabling automation mode.` No READY proof was obtained.
The user was asked to unlock the phone, check Enable UI Automation in Developer
settings and handle any confirmation. Do not claim that the app was launched,
connected, or that A/B performance improved on the phone yet.

The MCP startup process used Node 22.16 (too old for its USB forwarder). Startup
was retried through the plugin's documented phone.py entry with existing Node
24.21 in that process's PATH, preserving the shared runtime/session lock. No
independent phone controller or global Node changes were introduced.

## Planned comparison

Use one phone session to Mac 85; avoid simultaneous desktop viewers. Keep stream
geometry 1920x1080, frame ceiling 30, codec and test window fixed. Compare custom
quality 100 against speed-optimized quality. Run the same animation and read
several quality-monitor samples per profile, with a warmup. Record actual FPS,
transfer rate, target bitrate and reported network delay separately. Verify
clicks, typing, scroll and host physical display mode. Do not label automation
command duration or monitor network delay as input-to-photon latency.

Logs: /tmp/landesk-iphone85-{rust,flutter,sign,install}.log.
