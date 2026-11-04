# README 与官网素材更新（2026-11-03）

## 取图基线

文档审阅基线为 `main` 的 `62d093fec538e61c06d28e008911c13ff1c4e386`。界面实际运行产物为公开 Mac Apple Silicon 预览版 `v1.3.0-preview.20261030`、1.3.0（99），其应用源码版本为 `03e92c382b5f484a978039a95b8f96b52371217e`。不把当前文档基线冒充已编译应用的源码版本。

ZIP 的 SHA-256 为 `b73e8d74aab537ec26fde08b3ddda5b1ff1c95f8313a6a64697efd2446a3ef5f`，与 Release 的 `SHA256SUMS.txt` 一致。`codesign --verify --deep --strict` 通过；这是 Apple Development 签名的开发预览包，未公证。

## 截图与替换范围

截图来自真实 macOS Flutter 应用，窗口为 1100 × 760 逻辑像素，Retina 输出为 2200 × 1520，简体中文界面。只裁取完整应用窗口，不重画界面，不植入虚构设备。没有安装、覆盖或归档旧应用；运行的是临时解压的发布包，取图后结束本次应用及其子进程。

- `device-discovery.png`：实际初始发现页，尚未发现兼容对端，保留真实空状态及未完成的主机权限提示。
- `lan-settings.png`：从本机桌面卡片打开 LAN 设置，显示访问认证、端口、网络及发现选项。未填写或保存凭据，未切换网络或系统权限。
- `connection.png`：通过“添加”打开实际私有 IP 连接弹窗，未输入或提交真实地址及凭据。
- `assets/brand/landesk.png`：提取当前 `res/localdesk-icon.svg` 内嵌的原始 PNG；不重新设计图标。

中英文 README 同步换图，补充图注，并移除上游作者的微信二维码、上游社区邀请和旧 `master` 构建徽章分支。支持入口统一为 `quanru/landesk/issues`。保留 RustDesk 与 SubnetDesk 的署名和开源许可。

| 素材 | SHA-256 |
| --- | --- |
| `assets/screenshots/device-discovery.png` | `fc48dd1f3dcd7bafcea3bdf5dad41c3da4bcc20455ca00fcf83aa5cd1d04dadd` |
| `assets/screenshots/lan-settings.png` | `664b6e0cfff9077acb2b86007a61c1fae993604d8d7480f7d121ae395cfe39fb` |
| `assets/screenshots/connection.png` | `1a8993e15733fa5c6100593e79d4cc42f42d4651480de740e51c7aff3bc2c418` |

三张截图同时供 Studio 仓库 `apps/landesk-site/docs/public/screenshots/` 使用，两处文件哈希一致。官网三语文案区分公开 Mac 预览包、Nightly 与需邀请的 iPhone/iPad 内测；暂不登记尚未部署的官网 URL。

## 检查与范围

已检查中英文 README 的全部本地图片引用、PNG 文件头和尺寸，确认新截图不再显示 SubnetDesk 品牌，也不包含密码、私钥或个人会话内容。官网有独立的构建、类型检查和浏览器验收记录。

本轮只更新文档与素材，没有修改应用代码，没有验证远程控制会话、跨平台稳定性或性能，也没有发布安装包。

## 官网、下载与上游署名修订

正式官网为 https://landesk.lifeos.md/ ，中文入口 /zh/。中英文 README 增加各平台实际安装包的公开下载表，飞书固定文件为主、GitHub 为备；固定包均完成全字节 SHA-256 回读。TestFlight 公开组与链接已建立并关联 1.3.0（99），但尚未通过 Apple 外部审核，文案明确标记尚未开放、待外部审核。

Credits 明确 Fork 自 zibo-chen/SubnetDesk、基于 RustDesk，保留两级上游及贡献者署名、NOTICE 和 AGPL；不保留原作者联系方式或 Discord 邀请。`docs/landesk-common.md` 说明当前共享依赖 fork 的 5 个产品行为提交。

当前没有新增成功连接素材：手机 USB 安装尚未成功，已请用户完成一次安装；不把设置弹窗当成已连接画面。


## 2026-11-04 实连素材补齐

已使用 Android 35 备用模拟器上的 LanDesk 连接真实 Mac（`/Applications/LanDesk.app`，1.3.0 build 99），在空工作区中远程输入新建文本、向计算器发送 12 + 30，实际得到 42。中英文 README 首图替换为该会话截图；没有展示认证凭据、账号页面、聊天或私人文件。源视频和过程证据在 Studio `.verify/landesk-connected/`；公开截图与官网素材一致。保留现有 RustDesk、SubnetDesk 及贡献者 credit。


## 2026-11-04 Fork 来源纠正

GitHub API 返回 `quanru/landesk` 的 `fork=true`，`parent.full_name=rustdesk/rustdesk`、`source.full_name=rustdesk/rustdesk`。此前将 README 的 SubnetDesk 描述直接解释为 GitHub fork 链路，结论错误。中英文 README 与宣传文案已改为直接 fork 自 RustDesk；保留 SubnetDesk / zibo-chen 的既有致谢及全部 NOTICE、许可证，不据此推断代码引入历史。上方旧的“两级上游”判断以本节纠正为准。


## 2026-11-04 代码来源复核

补全原本只有 4 个提交的浅克隆历史后确认，SubnetDesk 的代码确实在当前应用中使用，因此保留相关致谢和 NOTICE。

- SubnetDesk 基线 `cdde2030deb18dcc148c13063b52c747dd3b448e` 是当前 HEAD `8225c97c4` 的祖先。
- LanDesk 提交 `0a4bc857028cb2c28fa5c9b79f7fc3cb101b4ef7` 的唯一父提交就是上述基线，提交说明明确为 “Base on SubnetDesk cdde2030”。
- `src/lan_server.rs` 由 SubnetDesk 的 `de81051cd4` 引入，当前文件相对上述基线仅新增 4 行，包括私有 IP 校验和测试断言；其余局域网服务实现仍在使用。
- mDNS 发现提交 `f5ac1ec575cc6d85fba6bf098f980b1358f62db2` 同样包含在当前历史中。

GitHub parent/source 为 RustDesk 只说明平台上的 fork 关系，不能排除后续接入其他项目代码。README 现明确区分这两件事；此前仅说“保留既有致谢”的表述不足以解释实际来源，以本节为准。本次未推送或发布。
