# 第三批 RustDesk 安全修复

日期：2026-11-04。LanDesk 源码基线 `b0d4fe177`，核对的 RustDesk 固定版本为 `55786aaa5709ac0a450aabcf06f9d1fee3119908`。本批接入 3 项，不表示全部安全差异已消除。

## 来源与适配

| RustDesk 提交 | 原作者 | 接入范围 |
| --- | --- | --- |
| `b44b71cfabe9898d5eada9b07cb583fe995ed45e` | fufesou | 校验下载文件名、列表和空目录路径；阻止路径穿越与链接目标；覆盖批准绑定具体条目，保护续传和 staging；写入与完成错误回传界面。 |
| `092a961b629d318fe290eeafac0cd214a1e9deeb` | RustDesk | 握手前即占用未认证名额，全局 64、每 IP 16、180 秒登录期限；满员只通知最老连接退出，新连接仍被拒绝。 |
| `dd9b21cf866d3f67f651f0002445894ab1897530` | RustDesk | 认证前限制帧为 128 KiB；本轮未登录时不发送单项或多项剪贴板广播。 |

下载逻辑适配当前 LAN 文件传输，未恢复已删除的公网与打印机分支。Flutter 按实际目标平台校验文件名。连接计数归一化 IPv4 映射地址，释放时按 guard 身份判断，避免 native/web 不同 Server 的重复 ID 误删名额。LAN 服务端从握手到登录保持小帧限制；控制端也在验签和密钥交换完成前限制握手消息。既有协议版本、签名和加密保持原实现。

`libs/hbb_common` 新的本地固定提交为 `2e7979e8bbd88b481457e012531d3e07017f9799`，仅增加 `Stream::set_max_packet_length`。两仓库均未推送；后续必须先推送 common 再推送主应用。保留 RustDesk、SubnetDesk 与原作者许可及 credit。

## 验证结果与边界

- `cargo test --locked -p base --lib`：23 个测试通过，包含 8 个下载安全测试。使用实际文件系统、临时目录和符号链接，未替换下载算法。
- `python3 tools/localdesk/test-lan-security.py`：15 个测试通过。临时 crate 直接编译生产 admission、prelogin、LAN 协议实现及实际 common/base；使用真实 loopback TCP、签名和加密。覆盖限额、驱逐、登录期限、IPv4 归一化、跨监听器重复 ID、超大帧、握手验签/防重放/降级及剪贴板登录门禁。未运行完整应用会话，未读取真实主机认证密钥。
- `flutter test --no-pub --concurrency=1 test/download_path_test.dart`：3 个回归通过。使用真实 FileController、路径校验和本地链接，FFI 为测试替身；不代表跨端文件传输已验收。
- 额外 Flutter 最小预览用例通过，截图 `/tmp/landesk-security-20261104/download-validation.png`。展示正常排队、拒绝 `../outside.txt` 和拒绝越界目录，属于测试预览，不是完整产品文件管理器或真实远程桌面。
- `cargo check --locked --lib --features flutter`：macOS arm64 宿主检查通过，70 条警告；没有宣称零警告或全部警告均为既有。
- LAN 残留检查、Flutter 工具链检查、`git diff --check` 通过。

编译使用 dev-gate heavy，定向检查使用 light；测试预览与工具均隔离。验证工具为 Rust 1.82.0、Flutter 3.44.1（官方归档 SHA-256 已核验）、FRB 1.80.1；临时 SDK、缓存和 native 验证依赖均在 `/tmp/landesk-upstream-tools/`，不进入源码依赖或 Git。Mac 检查使用实际构建的 libyuv 1857 及本机 Homebrew vpx/aom/opus，其中 aom 为 3.15.2；不是正式发版的固定 codec 产物。

尚未完成 Windows/Linux 目标构建、跨端真实下载/续传会话、移动设备安装和真实桌面连接验证。本轮未修复或验收虚拟键盘与旋转问题，未更新已安装应用、TestFlight、安装包或网站。没有推送、远端 CI 或发版。

此前两批文档中的工具链限制属于当时记录；本批已补上 Mac 整应用宿主检查，不能据此替代 Android/Linux/Windows 的专属验证。
