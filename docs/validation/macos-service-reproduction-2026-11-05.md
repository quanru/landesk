# macOS 服务与重复托盘复现

## 环境与范围

- 本机：macOS 27.0.1（26A434），Apple Silicon。
- 被测产物：已发布的 LanDesk 1.5.1（100），临时解压目录中的原始签名应用。
- `/Applications/LanDesk.app` 仍为构建 69；测试前暂时停止其用户态窗口和托盘，结束后恢复启动。未修改系统服务安装、用户配置或应用安装包。
- 用户报告发生在另一台 Mac，其版本及安装历史尚未确认。本记录不代表对另一台机器的远程实测。

## 已复现：重复菜单栏图标

使用同一构建 100 的可执行文件，分别运行主程序启动时使用的 `--tray` 入口和 LaunchAgent 使用的 `--server` 入口：

1. 仅 `--tray`：一个图标。
2. 加入 `--server`：两个相同图标，两个进程均在运行。
3. 停止本次 `--server`：恢复一个图标。
4. 清理本次测试进程，确认无构建 100 测试进程残留。

这是托盘入口的受控运行时复现，未通过点击安装服务及管理员授权完整重现安装流程。

原因：`src/landesk.rs` 的 `start_macos_tray` 启动独立 `--tray`；`src/core_main.rs` 中 macOS 的 `--server` 分支也直接运行 `start_tray()`。现有 `--tray` 进程检查不能排除后者，两条路径可以同时创建图标。因此不需要旧托盘进程参与，也能出现重复。

证据（本地忽略目录）：

- `.verify/macos-service-repro-20261105/isolated-tray/1-main-only.png`
- `.verify/macos-service-repro-20261105/isolated-tray/2-main-and-server.png`
- `.verify/macos-service-repro-20261105/isolated-tray/3-server-stopped.png`
- `.verify/macos-service-repro-20261105/isolated-tray/result.json`

## 尚未完整复现：每次启动要求安装服务

本机有 `com.carriez.LanDesk` 和 `dev.quanru.LocalDesk` 的 daemon / agent plist，但没有 `md.lifeos.LanDesk` 的两份 plist。当前源码 `is_installed_daemon(false)` 检查后者是否存在，因此本机的旧服务不能满足此判定。

这只是本机安装状态证据，不能证明另一台 Mac 同样因旧标签导致。尚未完成“安装成功 → 退出 → 重开”的完整验证，也没有将重新显示提示误报为已经复现。需要确认另一台版本、是否覆盖安装，以及安装后新标签的 plist 是否实际落盘。

## 附带发现与限制

第一次使用完整主窗口加 `--server` 的尝试出现主进程 SIGABRT，日志含 `mutex lock failed`。未判断崩溃根因；其结果不能当成正常安装流程通过。随后独立 `--tray` + `--server` 复测时两个进程存活，截图显示一至二至一的图标变化。

本轮只诊断、记录，没有修改产品代码、提交推送或发布新版。

## 后续复现：安装目录升级到构建 100

用户要求继续复现后，将 `/Applications/LanDesk.app` 更新为发布产物 1.5.1（100），保持用户数据不变。首次合并复制遗留了旧包资源，随后通过仅针对应用包的精确同步移除旧资源，`codesign --verify --deep --strict` 通过。当前本机应用版本为 100，不再是前文的 69。

实际打开主窗口后，左下角显示屏幕录制权限提示，暂时遮住安装服务入口。系统设置列表中 LanDesk 的录屏开关原本显示开启，但应用仍判定未授权；尚未确认此不一致的根因。通过正常界面尝试重新授予权限，点击开关时系统弹出密码认证窗口。已交由用户本人认证，未输入、猜测或获取密码，未绕过系统权限机制。

此阶段尚未点击安装服务，也尚未完成安装后重开验证。新的 `md.lifeos.LanDesk` 服务文件未由本轮创建。认证截图保存在 `.verify/macos-service-repro-20261105/installed100/permission-auth-required.png`。

## 用户认证后的进展（15:32—15:41）

- 用户完成系统认证后，正常开启录屏开关并重启，但应用仍判定未授权。
- 通过系统设置移除旧 LanDesk 录屏条目、明确重新选择 `/Applications/LanDesk.app` 添加并重启，录屏检测通过，提示转为辅助功能权限。
- 同样通过系统设置重新添加当前应用的辅助功能权限后，提示转为输入监控权限。
- 输入监控旧条目已移除，重新添加进行到文件选择器的“前往文件夹”界面时，Midscene 模型服务返回 `Arrearage`，重试后仍拒绝请求并停止。已移交用户完成当前应用添加，未切换凭据或通道绕过拒绝。
- 当前输入监控权限重新添加尚未完成；尚未点击安装服务，未完成“安装成功 → 退出 → 重开”验证。不能将权限提示和服务安装提示混为同一问题。
- 现场截图：`.verify/macos-service-repro-20261105/installed100/input-monitoring-pending.png`。

## SIWC 恢复与服务安装认证（15:49—15:50）

用户明确指定继续使用 SIWC。复用 Midscene 原生 SIWC 登录，通过正常刷新令牌恢复登录，模型列表返回成功，采用 `gpt-6.1-sol` / `gpt-6`。更新本机 `~/.env` 的 Midscene 认证模式、模型、家族和接口地址；未输出或迁移凭据。真实截图断言通过，桌面操作恢复。

输入监控权限重新添加并重启成功，LanDesk 主窗口左下角实际出现“为了开机启动，请安装系统服务”的安装卡片。已通过真实鼠标点击安装按钮，系统弹出安装脚本管理员密码认证。已移交用户本人完成；尚未宣称安装成功或完成重开验证。

## 完整安装与重开结果（15:57—15:58）

用户要求使用 SIWC + `gpt-6.1-terra`，已修改本机 Midscene 配置并通过真实截图断言。随后用户完成服务安装的管理员密码认证。

实际观察：

1. `/Library/LaunchDaemons/md.lifeos.LanDesk_service.plist` 和 `/Library/LaunchAgents/md.lifeos.LanDesk_server.plist` 均创建成功，均已登记到 launchd。
2. 左下角安装卡片消失；菜单栏出现两个 LanDesk 图标。此次是点击安装按钮并完成管理员认证的真实流程，不再只是独立进程入口的受控模拟。
3. 使用真实 Command+Q 退出主窗口，进程检查确认主程序退出，`--tray`（PID 59372）与 `--server`（PID 68139）仍运行。
4. 通过 LaunchServices 重新打开应用，主程序为新 PID 82497。左下角安装卡片没有重新出现；两个托盘图标仍存在。

结论：在本机 1.5.1（100）上完整复现了“安装服务后出现双图标”。成功安装后正常退出并重开没有再次提示安装，因此用户另一台 Mac 的“每次需要重新安装”仍未复现，不能认定与本机旧服务标签原因相同。未测试整机重启或另一台 Mac。

另外：旧 `com.carriez.LanDesk_service` 与 `dev.quanru.LocalDesk_service` 仍处于运行状态，新 daemon 查询时为 `spawn scheduled`、最后退出码 0，不能把 plist 存在等同于后台服务健康运行。本轮保持这些原有服务不动以保留现场，未执行服务迁移或清理。

证据：
- `.verify/macos-service-repro-20261105/installed100/after-install-state.json`
- `.verify/macos-service-repro-20261105/installed100/after-install-window.png`
- `.verify/macos-service-repro-20261105/installed100/after-install-trays.png`
- `.verify/macos-service-repro-20261105/installed100/after-reopen-window.png`

本轮仅复现与记录，未修改应用源码、提交推送或发布新版。

## 修复与验证（16:16）

- 新增 macOS 托盘文件锁，按用户隔离，在公共托盘创建入口持有。`--tray` 与 `--server` 无论先后顺序都只能由一个进程创建状态栏图标。锁文件位置不依赖 TMPDIR，关闭持有者后由系统释放锁；不删除锁文件以避免 inode 竞态。
- 一次性服务迁移工具接受已存在且身份核验通过的新启动项，保留其文件内容；迁移失败时恢复原先已加载的新旧服务。未把旧服务兼容分支加入应用运行时。
- 3 项定向测试通过：托盘互斥和释放恢复 1 项、并存迁移和失败回滚 2 项。Rust 定向测试以固定工具链编译实际模块并链接现有 libc 依赖，不代表全仓 Rust 测试。
- `cargo build --offline --locked --lib --bin service --features flutter` 在设置本机说明要求的 `LANDESK_LOCAL_VMAF_DIR=/opt/homebrew/lib` 后通过。开发候选签名校验通过。
- 使用修复后的原生核心和构建 100 的同接口 Flutter 外壳，在真实 macOS 菜单栏验证两种启动顺序，均只有一个图标；`--server` 持续运行。第二个独立 `--tray` 在锁已被服务持有时正常退出。两个入口分别设置 `/tmp/` 与 `/var/tmp/`，确认 TMPDIR 差异不会失效。
- 现场原有 LaunchAgent 和应用已恢复运行；开发候选未覆盖 `/Applications`，未发布新版。系统级旧服务清理仅做只读校验，未执行管理员迁移。
- 截图：`.verify/macos-service-repro-20261105/fixed/tray-then-server.png`、`server-then-tray.png`；进程证据 `fixed/result.json`。

回归影响范围：`src/lib.rs` 仅登记 macOS 模块；`src/tray.rs` 仅 macOS 创建托盘前持锁；新模块只负责锁生命周期。迁移工具仅改变显式执行时对已存在新启动项的处理。没有改变 Windows、Linux、移动端、连接协议或密码逻辑。
