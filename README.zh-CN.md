<p align="center">
  <img src="assets/brand/landesk.png" alt="landesk 图标" width="120">
</p>

<h1 align="center">landesk</h1>

<p align="center">
  <strong>面向局域网的远程桌面：连接直接、部署简单、数据路径可控。</strong>
</p>

<p align="center">
  Fork 自 <a href="https://github.com/zibo-chen/SubnetDesk">SubnetDesk</a>，基于 <a href="https://github.com/rustdesk/rustdesk">RustDesk</a> 独立维护，适用于局域网、可路由私网与 VPN。
</p>

<p align="center">
  <a href="https://github.com/quanru/landesk/releases/latest"><img src="https://img.shields.io/github/v/release/quanru/landesk?style=flat-square&logo=github&color=2563eb" alt="最新版本"></a>
  <a href="https://github.com/quanru/landesk/releases"><img src="https://img.shields.io/github/downloads/quanru/landesk/total?style=flat-square&logo=github&color=0ea5e9" alt="累计下载量"></a>
  <a href="https://github.com/quanru/landesk/stargazers"><img src="https://img.shields.io/github/stars/quanru/landesk?style=flat-square&logo=github&color=f59e0b" alt="GitHub Stars"></a>
  <a href="https://github.com/quanru/landesk/network/members"><img src="https://img.shields.io/github/forks/quanru/landesk?style=flat-square&logo=github" alt="GitHub Forks"></a>
  <a href="https://github.com/quanru/landesk/actions/workflows/localdesk-preflight.yml"><img src="https://img.shields.io/github/actions/workflow/status/quanru/landesk/localdesk-preflight.yml?branch=main&style=flat-square&label=build" alt="构建状态"></a>
  <a href="LICENCE"><img src="https://img.shields.io/github/license/quanru/landesk?style=flat-square&color=16a34a" alt="开源许可"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Windows-x64%20%7C%20ARM64-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/macOS-Intel%20%7C%20Apple%20Silicon-111111?style=flat-square&logo=apple&logoColor=white" alt="macOS">
  <img src="https://img.shields.io/badge/Linux-x86__64%20%7C%20ARM64-FCC624?style=flat-square&logo=linux&logoColor=111111" alt="Linux">
  <img src="https://img.shields.io/badge/Android-APK-3DDC84?style=flat-square&logo=android&logoColor=white" alt="Android">
</p>

<p align="center">
  <a href="https://landesk.lifeos.md/zh/">官网</a> · <a href="README.md">English</a> · 简体中文
</p>

<p align="center">
  <a href="#why-localdesk">项目定位</a> ·
  <a href="#features">主要功能</a> ·
  <a href="#download">下载安装</a> ·
  <a href="#quick-start">快速开始</a> ·
  <a href="#build-from-source">源码构建</a>
</p>

<p align="center">
  <img src="assets/screenshots/device-discovery.png" alt="当前 LanDesk 1.3.0 macOS 设备发现，展示初始空状态" width="880">
</p>

<a id="why-localdesk"></a>

以下截图取自真实 macOS 1.3.0（99）预览版，界面为简体中文。初始发现列表为空，发现附近兼容设备后才会显示设备卡片。

## 💡 为什么选择 landesk

landesk 专注于一个明确场景：让本身已经网络互通的设备直接进行远程控制。项目移除了 RustDesk 中的公网设备 ID、信令、中继、云账号、代理和公网自动更新等路径，改为直接连接目标地址，并自动发现局域网设备。

它适合家庭实验室、办公室、教室、现场运维，以及通过 WireGuard、Tailscale、OpenVPN 等 VPN 互通的私有网络。

| | landesk | 典型 RustDesk 部署 |
| --- | --- | --- |
| 连接方式 | 直接连接 私有 IP 地址 | 通过设备 ID 和信令服务连接，可使用中继 |
| 设备发现 | 局域网 mDNS 自动发现 | 设备 ID 或地址簿 |
| 服务依赖 | 无需协调服务器 | 设备 ID 连接通常需要公网或自建信令/中继服务 |
| 适用场景 | 局域网、可路由私网、VPN | 互联网和跨 NAT 访问 |

> [!IMPORTANT]
> landesk 不提供公网信令或中继服务。两台设备必须位于同一局域网、可路由的私有网络，或通过 VPN 实现网络互通。

<a id="features"></a>

## ✨ 主要功能

| | 功能 | 说明 |
| --- | --- | --- |
| 🔎 | 局域网发现 | 通过 mDNS 自动发现附近设备。 |
| ⚡ | 地址直连 | 使用 私有 IP 地址直接连接，TCP 端口可配置。 |
| 🔐 | 访问认证 | 使用用户名和密码保护访问，密码以 Argon2id 哈希保存。 |
| 🛡️ | 设备验证 | 首次连接时核对并保存设备指纹，降低误连风险。 |
| 🌐 | 网络白名单 | 通过 CIDR 网段限制允许接入的来源网络。 |
| ⭐ | 快速重连 | 保存最近设备、收藏与稳定设备身份。 |
| 🖥️ | RustDesk 体验 | 保留远程控制、剪贴板、音频和文件传输等能力，无需公网协调服务器。 |

<a id="download"></a>

## 📦 下载安装

[下载 macOS Apple Silicon 预览版（ZIP）](https://www.feishu.cn/file/B3xNbSIJboMZIExIwFvcuM1onBe) · [GitHub 备用下载](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261030/landesk-1.3.0-99-macos-arm64.zip) · [发布说明与 SHA-256 校验](https://github.com/quanru/landesk/releases/tag/v1.3.0-preview.20261030)

这是开发预览版，使用 Apple Development 证书签名，**尚未公证**，其他 Mac 的 Gatekeeper 可能阻止打开；它不是 Developer ID 正式发行包。压缩包内为 `LanDesk.app`，保留原有应用标识以兼容升级。首次安装可解压后复制到“应用程序”；已有 `LocalDesk.app` 请先阅读[名称迁移步骤](docs/validation/macos-name-migration-2026-10-29.md)，同步迁移后台服务路径。

下表列出当前公开的桌面端和 Android 安装包，均为预览版或 Nightly，尚非稳定版；部分文件名仍使用旧名称 LocalDesk。iPhone、iPad 仅作控制端，[TestFlight 公开链接](https://testflight.apple.com/join/gFHTx8Xy)已启用，安装需等待 Apple 外部测试审核通过。

| 平台 | 主下载 |
| --- | --- |
| macOS Apple Silicon · 1.3.0 (99) | [下载 / Download](https://www.feishu.cn/file/B3xNbSIJboMZIExIwFvcuM1onBe) · [GitHub](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261030/landesk-1.3.0-99-macos-arm64.zip) |
| Windows x64 · Nightly | [下载 / Download](https://www.feishu.cn/file/RqVqb6mewo2pFvxbBXXcvhi1nIe) · [GitHub](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.exe) |
| Linux x64 DEB · Nightly | [下载 / Download](https://www.feishu.cn/file/Ek28bEqTEoPWGmxDRN5cdrhenPe) · [GitHub](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.deb) |
| Android ARM64 · Nightly | [下载 / Download](https://www.feishu.cn/file/X8Pnbi6jOoh0jZxYq5RcQZ21nYe) · [GitHub](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64-signed.apk) |
| iPhone / iPad | [TestFlight](https://testflight.apple.com/join/gFHTx8Xy) （外部测试审核中） |

<details>
<summary>其他架构与安装格式（GitHub 备用下载）</summary>

| 平台 | 公开下载 |
| --- | --- |
| macOS | [landesk-1.3.0-99-macos-arm64.zip](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261030/landesk-1.3.0-99-macos-arm64.zip) · [localdesk-1.3.0-aarch64.dmg](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.dmg) · [localdesk-1.3.0-x86_64.dmg](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.dmg) |
| Windows | [localdesk-1.3.0-aarch64.exe](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.exe) · [localdesk-1.3.0-aarch64.msi](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.msi) · [localdesk-1.3.0-x86_64.exe](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.exe) · [localdesk-1.3.0-x86_64.msi](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.msi) |
| Linux | [localdesk-1.3.0-0-x86_64.pkg.tar.zst](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-0-x86_64.pkg.tar.zst) · [localdesk-1.3.0-0.aarch64-suse.rpm](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-0.aarch64-suse.rpm) · [localdesk-1.3.0-0.aarch64.rpm](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-0.aarch64.rpm) · [localdesk-1.3.0-0.x86_64-suse.rpm](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-0.x86_64-suse.rpm) · [localdesk-1.3.0-0.x86_64.rpm](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-0.x86_64.rpm) · [localdesk-1.3.0-aarch64.AppImage](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.AppImage) · [localdesk-1.3.0-aarch64.deb](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.deb) · [localdesk-1.3.0-aarch64.flatpak](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64.flatpak) · [localdesk-1.3.0-x86_64.AppImage](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.AppImage) · [localdesk-1.3.0-x86_64.deb](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.deb) · [localdesk-1.3.0-x86_64.flatpak](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64.flatpak) · [localdesk-unattended-wayland-1.3.0-x86_64.deb](https://github.com/quanru/landesk/releases/download/nightly/localdesk-unattended-wayland-1.3.0-x86_64.deb) |
| Android | [localdesk-1.3.0-aarch64-signed.apk](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-aarch64-signed.apk) · [localdesk-1.3.0-armv7-signed.apk](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-armv7-signed.apk) · [localdesk-1.3.0-universal-signed.apk](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-universal-signed.apk) · [localdesk-1.3.0-x86_64-signed.apk](https://github.com/quanru/landesk/releases/download/nightly/localdesk-1.3.0-x86_64-signed.apk) |
| iPhone / iPad | [TestFlight](https://testflight.apple.com/join/gFHTx8Xy) （外部测试审核中） |

</details>

<a id="quick-start"></a>

## 🚀 快速开始

1. 在两台设备上安装并打开 landesk。
2. 在被控端从本机桌面卡片打开 **LAN 设置**，设置用户名和密码，并开启局域网发现。默认端口为 `21118`。
3. 在控制端选择已发现的设备，或手动输入 `IP:端口`。
4. 首次连接时核对设备指纹，确认无误后发起连接。

<p align="center">
  <img src="assets/screenshots/lan-settings.png" alt="landesk LAN 设置" width="880">
</p>

### 网络检查清单

- 两台设备之间路由可达。
- 主机防火墙已允许 TCP `21118` 端口，或你自行配置的端口。
- 自动发现需要网络支持 mDNS；即使 mDNS 不可用，仍可手动输入地址直连。
- 被控端的 CIDR 白名单包含控制端所在网段。
- Linux 用户可查看[主机环境说明](docs/linux-host-readiness.md)，了解 SELinux、Wayland 与登录界面的注意事项。

### 私有 IP 直连

点击“添加”打开连接弹窗，输入私有 IP，需要时展开用户名与密码。信任新设备前，请先核对指纹。

<p align="center">
  <img src="assets/screenshots/connection.png" alt="当前 LanDesk 私有 IP 直连弹窗" width="880">
</p>

## 🔒 安全模型

- 数据沿设备之间的可达网络路径传输，不依赖公网协调服务。
- 密码使用 Argon2id 哈希保存，不以明文持久化。
- 设备指纹采用首次使用信任机制，可帮助识别目标设备身份的异常变化。
- CIDR 白名单可限制被控端接受连接的来源网络。

与其他远程控制软件一样，请只向可信网络开放监听端口，使用高强度且不重复的密码，并尽可能通过另一条可信渠道核对设备指纹。

会话数据、本地存储、更新请求和删除方式，请参阅 [landesk 隐私政策（英文）](PRIVACY.md)。

<a id="build-from-source"></a>

## 🛠️ 从源码构建

拉取仓库及其子模块，然后执行 Flutter 桌面端构建：

```bash
git clone --recurse-submodules https://github.com/quanru/landesk.git
cd landesk
./build.py --flutter --hwcodec
```

构建需要 Rust、Flutter 和对应平台的原生依赖。固定工具版本、目标架构和完整打包步骤以[原生安装包工作流](.github/workflows/flutter-build.yml)为准。

固定的 `libs/hbb_common` 子模块包含 LanDesk 的私有 IP 校验与局域网配置修改，当前需要保留独立 fork。详见 [依赖维护说明](docs/landesk-common.md)。

## 🤝 参与贡献

欢迎提交缺陷报告、功能建议和 Pull Request。开始修改前建议先查看现有 [Issues](https://github.com/quanru/landesk/issues)，并尽量让改动保持聚焦，符合项目面向局域网与 VPN 的产品定位。

## 问题反馈

请通过 [GitHub Issues](https://github.com/quanru/landesk/issues) 报告缺陷或提出建议，不要附带访问凭据或敏感会话内容。

## 🙏 致谢与许可

LanDesk Fork 自 [zibo-chen](https://github.com/zibo-chen) 维护的 [SubnetDesk](https://github.com/zibo-chen/SubnetDesk)，后者基于 [RustDesk](https://github.com/rustdesk/rustdesk)。感谢这两个上游项目及其贡献者提供的远程桌面基础与局域网适配工作。

本项目由 [quanru](https://github.com/quanru) 和贡献者独立维护，并非任一上游的官方发行版。保留原有版权声明、[NOTICE](NOTICE)、AGPL-3.0 许可与第三方依赖许可证。

项目采用 [GNU Affero General Public License v3.0](LICENCE) 许可。请仅在自己拥有或已获授权的设备上使用远程控制功能。

## License and source / 开源许可与源码

See [NOTICE](NOTICE), [AGPL v3](LICENCE), [version-specific sources](docs/licensing/releases.md), and [build/dependency coverage](docs/licensing/README.md).
