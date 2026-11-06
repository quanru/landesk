# RustDesk 上游同步记录

本次在 `main` 合并官方 RustDesk 的 10 个提交。旧基线为 `55786aaa5709ac0a450aabcf06f9d1fee3119908`，固定目标为 `91e43e24ea16d69d2d359061cd4d56c55d9b63a3`，同步前本地主线为 `a036a1df25b4b960f2a5a1c376bf03fd21bfe079`。

使用正常的 `--no-ff --no-commit` 合并，无文本冲突。72 个上游文件的新增、删除行与官方差异逐文件核对一致，没有另外修改运行时代码。`libs/hbb_common` 仍为 `fae47e024dd83cef6aaecde0aa7d11731df11649`，没有依赖或子模块升级。同步前的两处移动端侧栏 WIP 临时保存，合并提交不包含这些改动。

原始影响报告见 [upstream-sync-2026-11-06-impact.json](upstream-sync-2026-11-06-impact.json)。该报告记录保存 WIP 前的状态，因此 `working_tree_clean` 为 false；实际合并开始时工作区干净。

## 回归范围

以下为本次同步改变的已有文件与路径，均来自固定上游范围；完整清单见影响报告的 `incoming_files`。

- `src/ipc.rs`、`src/ipc/auth.rs`、`src/server.rs`：Windows 主进程和服务 IPC 的权限、服务端身份校验与 GUI 监听失败处理；Unix IPC 循环移入 `start_with_listener`，原调用入口保留。新增 Windows 模块及回归测试随上游一同接入。
- `src/platform/windows/installer_handoff/directory.rs`、`src/platform/windows/installer_shell.rs`：安装临时目录遇到 junction 时使用经校验的 ProgramData，要求文件系统支持持久 ACL；新增对应安全测试。
- `src/platform/privileges_scripts/daemon.plist`：macOS 服务由 launchd 直接启动，移除 shell 包装。LanDesk 的路径和服务名仍由现有 `correct_app_name` 替换。
- `src/client.rs`、`src/common.rs`、`src/rendezvous_mediator.rs`：限制 relay UUID 和请求中的 relay 地址。LanDesk 的 `_start` 仍只调用 `connect_peer`，`start_all` 仍只启动 LAN 发现和直连服务，没有恢复公网连接入口。
- `src/port_forward.rs`、`src/port_forward_mux.rs`、`src/ui_session_interface.rs`：保留 KCP 句柄、处理登录期间关闭并发送关闭原因；端口转发窗口退出新增 100 ms 等待。LanDesk 当前使用 TCP 直连，KCP 测试验证上游实现，不代表产品启用了 KCP。被控端仍通过 `connect_forward` 校验转发目的地址。
- `src/lang.rs`、`src/lang/*.rs`、`flutter/lib/common/widgets/dialog.dart`：兼容 Android 旧语言代码、修正印尼语翻译，将受信设备无限期显示为 Forever。受信设备仍由 LanDesk 固定设置禁用；没有手工改动翻译。
- `.github/workflows/flutter-build.yml`、`.github/workflows/flutter-nightly.yml`：接入上游更新元数据工作流调整，保留本地手动触发限制。未增加 push、pull_request 或 schedule 触发，未运行远端 CI。

以上改动用于完整接入本批上游修复。最小化复查未发现额外清理、重构或品牌调整；本地只更新基线与验证记录。`release_ready` 保持 false。

## 验证

- macOS 服务迁移 Python 测试：2 项通过；测试使用临时环境，没有修改系统服务。
- 对 `dialog.dart` 运行 Dart analyze：无错误或警告，9 条 info 均为未修改行的 API 弃用提示。
- daemon plist 解析通过，`ProgramArguments` 只有服务可执行文件。
- 上游 72 个文件的增删行完整性检查、手动工作流触发检查及 `git diff --check` 通过。

- `cargo test --offline --locked --lib --features flutter --no-run` 在 macOS arm64 编译通过，编译器报告 83 条 Rust 警告，未在本次同步中清理。
- 运行该测试产物的定向回归：41 项通过，包括 LAN 地址策略 4 项、relay 校验 4 项、转发模块 24 项（含真实 loopback KCP 传输与关闭原因）、语言模块 8 项、macOS 服务标识 1 项。各过滤器均核验实际执行了测试。

本地日志：`/tmp/landesk-upstream-tests-20261106.log`、`/tmp/landesk-upstream-regressions-20261106.log`、`/tmp/landesk-upstream-service-20261106.log`、`/tmp/landesk-upstream-dart-20261106.log`。

验证使用现有 `/tmp/landesk-upstream-tools/run.py` 工具链和本机开发依赖，编译经 dev-gate heavy，轻量检查经 light。未验证 Windows/Linux 目标构建、跨端真实连接或新版应用界面截图；受信设备文案所属功能在产品中禁用。未安装应用、推送或发布，不将这些检查视为跨平台发行验收。
