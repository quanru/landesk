# LanDesk 原生迁移范围

本文描述当前 `main` 分支；尚未发布。固定官方基线见 `tools/migration/native-baseline.json`。

## 连接与认证

- 原生客户端只接受数值私网 IP（含回环、链路本地、Tailscale 使用的 CGNAT 段、IPv6 ULA），不解析公网 ID 或主机名，不走代理、会合、NAT 穿透或中继回退。
- 原生 TCP 直连使用官方未加密传输；加密由 Tailscale／VPN 等外层提供。这不取消官方密码、被控端批准和会话权限。
- 远控仅使用原生客户端；内置 HTTPS 浏览器网关和 Web 客户端已按用户要求移除。
- 端口转发目标同样只接受数值私网地址；`localhost` 仅映射到回环地址。
- 局域网发现、最近连接、收藏、自定义虚拟按键与主题继续保留。

## 配置与上游代码

使用新的 LanDesk 配置命名空间，不读取或转换旧 LocalDesk 协议、账户、公钥、凭据或布局。macOS 配置位于 `~/Library/Preferences/dev.quanru.LanDesk/`。

本轮以官方源码为基础禁用线上服务启动和入口；部分未调用的上游实现仍留在源码中，不能声称它们已全部删除。保留 AGPL 许可证、RustDesk 致谢及实际依赖的版权声明。旧版本来源见 legacy 和历史审计记录。

## 验证边界

已通过的编译、测试和实测记录见 `docs/validation/native-migration-progress-2026-11-04.md`。本机监听成功不代表真实桌面、输入、旋转及各平台均已验收。没有把第三方 TLS 依赖的存在当成公网连接证据，也没有宣称完成全进程抓包审计。
