# LanDesk privacy

Updated: 2026-11-05. This policy describes the native RustDesk-based LanDesk 1.5.1 preview. Earlier builds on the `legacy` branch use a different implementation.

## Connections and session content

LanDesk connects native clients directly using private IP addresses. It does not provide a LanDesk cloud account, public device-ID lookup, rendezvous service, NAT traversal or application relay. Screen images, input, clipboard content, audio and transferred files travel between the connected devices when the corresponding session features are enabled. The project does not operate a service that receives that session content.

**Native direct-IP session traffic is not encrypted by LanDesk.** Password verification and host approval control access; they do not make the transport encrypted. Use an encrypted network such as Tailscale or another VPN when confidentiality is required. That network provider's policies and transport choices apply separately.

LAN discovery broadcasts device information on the local network so that nearby clients can find hosts. Use direct-IP entry and disable discovery if you do not want discovery announcements.

## Information on your devices

LanDesk stores settings, authentication configuration, recent peers and diagnostic logs locally. Depending on enabled features, devices may also retain transferred files, clipboard data or session recordings. Treat local application data and exported logs as sensitive. Old configuration is not imported by the native migration; updating does not promise to erase old application data.

Operating-system permissions control screen capture, accessibility/input, audio and other platform capabilities. Enable only the permissions needed for your intended use. You can change them in system settings and change password/approval and session permissions in LanDesk.

## Websites and distribution

The website is hosted separately from the application. Website hosting, GitHub downloads, Feishu downloads, Apple TestFlight and App Store distribution are subject to their providers' policies. Apple may collect beta crash and usage information through TestFlight. Opening an external link contacts that provider; it does not route your remote desktop session through the LanDesk website.

## Reports and questions

Use [GitHub Issues](https://github.com/quanru/landesk/issues) for product and privacy questions. Issues are public: do not include passwords, keys, private files, full configuration or private session contents. Review and redact logs before sharing them.

LanDesk is an independent fork of RustDesk, not an official RustDesk service. Source code and retained license notices are available in [this repository](https://github.com/quanru/landesk).
