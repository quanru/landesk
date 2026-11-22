# Linux host readiness

LocalDesk shows host-readiness warnings when the current Linux environment may
prevent reliable incoming remote-control sessions. These warnings do not affect
outgoing connections.

## SELinux

When SELinux is enforcing, its policy may block screen capture, input injection,
or background-service access even if LocalDesk itself is running.

1. Check the recent denial records with `sudo ausearch -m AVC -ts recent`.
2. Confirm that the denial was produced while reproducing the LocalDesk issue.
3. Add the narrowest local policy required for that operation. Do not disable
   SELinux globally as a first troubleshooting step.

You can dismiss this warning after the host policy has been configured.

## Wayland session

Wayland support remains limited for unattended control. Screen capture and input
injection depend on the compositor and may require an interactive permission
prompt after every login.

For a Linux machine that must remain remotely accessible without a local user,
select an X11 session from the display manager and then sign in again. You can
continue using Wayland when interactive approval and the compositor's supported
feature set are acceptable.

### Hyprland：只有 ScreenCast 接口时

2026-11-17 在 Omarchy 4.5.0／Hyprland 的物理桌面上复测 Linux
1.5.1 (101)：系统提供 `org.freedesktop.portal.ScreenCast`，但没有
`org.freedesktop.portal.RemoteDesktop`。直接启动便携版 GUI 时，连接批准后会因
缺少 RemoteDesktop 接口而失败。

现有服务模式使用另一条路径：系统服务以 root 运行 `landesk --service`，派生
桌面用户的 `landesk --server`，通过 ScreenCast 获取画面、通过 uinput 注入输入。
因此，只有 ScreenCast 接口不代表服务模式也不可用。该路径仍需要在已登录桌面中
正常批准连接和屏幕共享，不能据此保证登录界面控制或无人值守重连。

若共享选择器不显示可选屏幕，检查 `~/.config/hypr/xdph.conf` 的
`custom_picker_binary`。本次环境中的 `hyprland-preview-share-picker` 因无法解析
Hyprland JSON 的 `id` 字段而失败；临时改为标准 `hyprland-share-picker` 并重启
用户服务 `xdg-desktop-portal-hyprland.service` 后，正常选屏并成功传输 2560×1600
画面。重启门户会影响正在使用它的共享会话，应先结束相关会话。

Mac 自动化合成按键在输入源 1 仍有修饰键兼容问题。输入源 2 原先能正确传递 Shift，
但小键盘数字因 Num Lock 标记关闭而成为导航键。Flutter 路径补齐原生 Mac 的
Num Lock 恒开约定后，15 项定向测试通过；加载本地 Debug 1.5.1 (102) 客户端后，
Mac → 这台 Linux 的画面、完整文本 Linux_OK_125、Ctrl+A 替换文本及按钮点击均
通过真机复测。该结论限于服务模式和输入源 2，不包含其他合成器或 Android 客户端。

上述 101 版本验证不包含 Linux App 模式。

### Linux App 模式开发候选

2026-11-17 新增 Hyprland 0.57.x 的窗口枚举、聚焦、按手机比例调整窗口及恢复逻辑，
复用已有 App 模式协议。当前仅支持原点为 (0, 0)、未旋转的单显示器；其他环境不声明
此能力，手机不显示 App 选择入口。该功能仍传输桌面后在手机裁剪窗口，不能隔离
其他窗口或系统浮层的遮挡。

完整 Linux Rust 主机编译通过。2026-11-17 的后续候选通过 7 项 Flutter 触摸、手势及
App 模式定向测试，另有此前通过的 2 项 Linux 原生模块测试。

Android 辅助触摸重放导致一次点击成为双指手势的问题已修复。软键盘展开后的点击
误拦截也已修复：画布触点相对 SafeArea，键盘工具条矩形相对屏幕；仅在比较这两者时
补上安全区偏移。新增回归测试在修复前失败，修复后通过。

Redmi K30 Ultra（Android 12）实际连接 Omarchy／Hyprland 0.57.1 物理主机后，
竖屏选择 LanDeskNotes，先取消输入框焦点、展开软键盘，再点回输入框，通过屏幕
键盘逐键输入 `Linux_OK_125` 并保存成功。旋转横屏、切换到 LanDeskTasks 后，
同样重新点击输入框，逐键输入 `A_1` 并保存成功；两个应用各收到两次预期按钮回调。
切换时前一窗口恢复，手机正常断开后两个窗口的位置及浮动状态恢复，尺寸误差不超过
1 个逻辑像素。此前也验证了主机断开和客户端进程结束后的窗口恢复。

此次测试 APK SHA-256：
`a3951f676827020e7dfb6ec047c70d7880d364e6c9c2118dc86147fb2a3f6167`。
证据记录于本地 `.verify/keyboard-safe-area-20261117/report.md`；这是复用既有原生核心、
重新构建 Flutter UI 的开发候选，不是正式发行版。

测试结束已停止本次实例，恢复共享选择器、自动屏保、锁屏、手机自动旋转设置，并移除
本次防火墙规则。首次 Wayland 文字输入确认会单独保留；App 列表和确认入口不再被该
文字输入开关禁用。验收范围限于上述单屏环境；横屏软键盘仍会压缩可见画布，不包含
其他合成器、多显示器或 Windows 手机端到端验证。

## Wayland login screen

A Wayland login screen cannot be controlled before the desktop session starts.
This also prevents reconnecting to the login screen after logout.

Configure the display manager to use X11 for its greeter. The exact setting is
distribution-specific; consult the display manager documentation before editing
system configuration, then restart the display manager or reboot the host.

LocalDesk reports the login-screen warning separately from the current desktop
session because the greeter and the signed-in desktop can use different display
servers.
