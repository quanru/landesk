# 官方基线迁移进度

## 当前结论（2026-11-05 02:24）

整体迁移尚未完成，仍在 `migration/rustdesk-native`，没有提交推送或发布。

| 范围 | 当前结果 |
| --- | --- |
| 官方 RustDesk／common 基线与生成桥 | 已切换并通过 Mac／iOS 构建，不载入旧握手或配置 |
| Mac 被控、浏览器访问 | 实连、错误／正确密码、手动批准、输入、权限关闭／恢复通过 |
| iOS 控制真实 Mac | 模拟器实连与密码认证通过，系统键盘输入、虚拟按键输入通过 |
| iOS 键盘与旋转 | 默认按键不重叠；横屏真实桌面、系统键盘开合、侧栏恢复通过；物理多点与硬件键盘未验收 |
| Android | Android 35 模拟器实连、密码认证、系统键盘／虚拟键输入通过；横屏键盘遮挡修复已实测；真机安装受限 |
| Linux | 现有设备 SSH 不可达，未验证 |
| Windows | 未构建、未运行 |
| 文件、音频、终端、转发 | 官方实现已接入，完整功能验收未完成 |
| 网络范围 | 源码路径和地址单测通过，当前 host socket 只见本机／LAN；不等于完整外联抓包审计 |
| 发布与升级安装 | 未执行；公开下载仍指向迁移前版本 |

关键截图：`assets/screenshots/native-ios-connected.png`、`native-ios-system-keyboard.png`；输入及浏览器权限证据在 `.verify/native-runtime/`。以下为历史流水，早期阻塞以本表和后续实测为准。

分支：migration/rustdesk-native。当前阶段：原生非加密直连与上游认证接入。未发布、未安装，尚未完成真实远控连接。

## 早期原型记录（源码切换前）

- 固定主应用 55786aaa5709ac0a450aabcf06f9d1fee3119908 和官方 common fae47e024dd83cef6aaecde0aa7d11731df11649，不导入旧协议或用户配置。
- tools/migration/prepare-native.py 导出独立源码，检查子模块提交是否匹配。已有目录拒绝覆盖，不创建工作树，不修改当前源码或子模块检出。
- native_address_policy.rs 实现数值地址准入，支持私网、回环、链路本地、Tailscale 所在共享地址段及 IPv6 ULA；拒绝公网、未指定、组播、非法端口、主机名和非标准地址表示。共享地址段获准不代表连接已通过 Tailscale 认证。
- native-policy.patch 接入官方源码的客户端、直连监听和启动入口。启动入口不再启动该入口内的 NAT 探测、云同步、更新器及会合循环。
- 按用户后续明确选择，已移除客户端强制加密检查和服务端全部拒绝直连的临时阻断。通过私网检查后使用官方 create_tcp_connection，secure=false；上游登录认证与权限处理文件保持不变。源码接通不等于真实连接验证完成。

默认导出为未改官方源码；加 --with-policy 才应用原型。仍有其他启动入口和网络调用待核对，不宣称整个应用已经没有公网请求。原有应用源码仍保留作为对照，当前实际原型修改通过可重放补丁应用到官方导出目录；尚未进行整个仓库的源码替换。

## 原生直连行为与当前选择

以下引用均针对固定官方快照：

- src/client.rs 的 Client::_start 在 IP 直连分支直接返回 TCP Stream，没有调用 secure_connection。
- src/rendezvous_mediator.rs 的 direct_server 以 secure=false 调用 create_tcp_connection。
- src/server.rs 的 identity_handshake 仅在 secure=true 且密钥有效时执行密钥交换。
- src/client/io_loop.rs 对直接 IP 访问跳过不安全连接确认。
- secure_connection 在缺少可信签名身份或部分校验失败时存在非加密回退，不能简单改为调用这个函数就认为安全。

这是源码调用链检查结果，尚未抓包或运行官方客户端。不能据此宣称所有 RustDesk 连接都不加密。用户已明确接受此模式，将传输加密交给外部网络层；这不授权移除密码认证。

此前计划的可信公钥接入与额外握手不再实施。保留以上源码观察以说明产品边界，不再将非加密直连列为阻塞。浏览器 HTTPS 等独立传输要求不在本次取消范围内。

## 已执行验证

- 固定官方主仓库与子模块导出成功，原型补丁 git apply --check 和实际应用成功。
- 地址策略使用 Rust 1.82 编译，通过 4 组单元测试，覆盖地址范围边界、IPv4 映射、公网／组播拒绝、端口和禁止主机名。
- 本轮重新导出并应用非加密直连补丁成功。核对 src/server/connection.rs、src/server.rs、src/client/io_loop.rs 和 libs/base/protos/message.proto 均与官方基线逐字节一致，未改认证或协议。
- 已尝试 Rust cargo check；离线检查因未缓存 Git 依赖失败，正常联网拉取取得 tungstenite 固定提交，但 webrtc 拉取持续无输出，主动结束本次检查并释放 heavy，改用有时限的固定提交浅拉取，55 秒超时并返回 early EOF。尚未完成整应用编译或运行设备，因此没有真实连接和界面截图。上述单元测试不证明整个应用网络限制有效。

## 后续顺序

验证上游密码认证、手动批准及双方真实会话；完成其他网络入口审计和独立配置；再接入品牌、主题、输入模块及其他端。整个过程不加入旧协议、配置转换或降级兼容。


## 2026-11-04 源码迁移阶段

已在 `migration/rustdesk-native` 将主应用源码切换至固定官方快照，common 子模块切到官方固定提交。HEAD 尚未提交，当前包含官方快照的暂存变更及产品适配的工作区变更。主分支未改动，未推送、安装或发布。

- `src/landesk.rs` 负责独立配置名称、固定产品开关及数值私网连接。原生连接直接使用校验后的 SocketAddr，不经过 SOCKS、DNS 或公网回退；端口转发同样校验目标。
- LAN 发现使用上游 UDP 协议，广播实际监听端口；连接地址取回复来源 IP，不能由广播内容指定任意目标。
- 启动不运行会合、NAT、云同步或更新检查；禁用云 HTTP、服务器测试和修改公网 ID 的入口。完整进程级外联审计尚未完成。
- 接入已有 LanDesk 主题、品牌及移动端独立输入控件，清除旧键盘配置导入；迁移后使用独立布局目录。横竖屏都接入虚拟键盘入口。旋转延迟回调增加页面存活和方向检查。
- 官方重新引入的自动 CI 触发已改为手动入口，不触发远端构建。

本轮证据：

- Rust 1.82 独立编译 `src/landesk_native_policy.rs`，4 项策略测试通过。
- Flutter 3.44.1：主题、远程组合键、自定义键盘控件共 24 项测试通过，含双指按住、释放、窗口尺寸变化释放和配置存储。
- `cargo check --offline --locked --lib --features flutter` 已完成依赖编译并进入应用检查，但旧生成桥仍引用 SubnetDesk 接口，检查失败。客户端替换同时遗漏了未使用的上游辅助函数，已补回；尚未重新通过编译。
- Dart 定向分析未发现新增远程控件和拆分页面的类型错误；公共模块仍报 10 项旧桥缺失方法，不能标为分析通过。
- 重新生成桥前发现新基线 AGENTS.md 明确禁止本机 codegen（因固定版本安装困难）。所需 1.80.1 实际已准备好，已停止本次生成进程并请求用户允许本次固定版本生成，等待回复。未手工伪造接口结果。

未完成：生成接口与整应用构建、真实密码及授权验证、连接桌面截图、移动旋转及坐标验证、浏览器网关迁移、跨平台安装与回归。现有测试不构成整体迁移完成，也不证明已无公网请求。

补充：输入回归批次中，依赖公共 FFI 的 remote_input_stack 测试因旧生成桥缺失接口而无法加载；该批次整体失败，不能将独立控件通过结果当作整批通过。当前已释放本轮构建额度。


## 本次授权后的进展

用户已明确允许使用固定 codegen 1.80.1。生成 Rust/Dart/C 接口及 Freezed 文件成功；Flutter 全 lib 分析无 error（仍有上游 warning/info），原生核心 cargo check 通过。

浏览器网关已恢复并改接 `create_tcp_connection(..., secure=false, ...)`，保留 HTTPS、Origin/Host 校验及限流；前端改用官方 Hash/LoginRequest 消息，不包含旧握手或口令转换。浏览器侧 16 项单测、TypeScript 类型检查及资源构建通过，网关运行尚未验证。

新增原生设置页，展示真实局域网地址、直连端口与 HTTPS 网关开关；上游 IPC 在线状态改为本机监听状态。增加网关配置变更的独立重启处理，不重启现有原生会话。禁用最近设备列表的公网在线查询。

画布尺寸改用侧栏和安全区域内的实际布局约束；迁回聊天浮层尺寸修复与 BlockableOverlay 刷新修复。输入/浮层/侧栏专项复测 12 项全部通过。它们仍不是实际桌面输入证据。

首次本机链接因 Homebrew libaom 的额外 VMAF 依赖失败；添加显式本机构建选项 LANDESK_LOCAL_VMAF_DIR，使用 macOS 12.3 部署目标重新构建。尚未生成本轮可运行应用，未安装或发布。


## 2026-11-05 本机运行进展

- macOS ARM64 原生库、service 和 Flutter Debug 应用已构建成功，并通过开发签名校验。应用在构建目录运行，没有替换 `/Applications/LanDesk.app`，未发布。
- 新配置实际位于 `~/Library/Preferences/dev.quanru.LanDesk/`；独立测试端口 21218（原生）与 18223（HTTPS）均监听成功。首次启动等待 root IPC 的日志不代表直连服务失败。
- 浏览器真实连接：错误密码返回 `Wrong Password`；空密码弹出被控端授权窗口；手动点击接受后持续接收 3840×2160 桌面，观察约 6 FPS、0 dropped、VP9。截图 `.verify/native-runtime/browser-connected.png`，时间 2026-11-05 00:17 左右。该证据使用这一阶段候选，不冒充后续改动的最终验收。
- HTTPS 网关 24 项定向 Rust 测试通过；Web 16 项测试、类型检查和构建通过；虚拟按键、按住释放、输入浮层及侧栏共 17 项 Flutter 测试通过。
- 浏览器界面改为消费官方 PermissionInfo；删去旧 Web 权限 profile 与 LAN 设置回退；原生首页移除 ID／自建服务器误导文案。虚拟按键显示状态现在同步至侧栏，避免读取隐藏配置后按钮仍显示选中。
- iOS 模拟器原生依赖已从源代码构建；当前在编译新 Rust 核心。移动端实际键盘、旋转、坐标和跨平台验收仍待完成。
- 整体迁移尚未完成：正确密码的无人值守连接、最终候选输入与权限切换、移动端实际远控及其他平台构建仍待验证。未宣称全进程公网流量审计完成。


### 00:44 补充

最新 Mac 候选通过正确一次性密码自动连接。浏览器发送测试字符串，真实 Mac TextEdit 已收到；被控端关闭键盘权限后，浏览器 `viewOnly=true` 且文字框隐藏，重新打开后恢复输入。截图分别为 `.verify/native-runtime/browser-input.png`、`browser-permission-off.png`、`browser-permission-restored.png`。浏览器初始剪贴板按钮显示另有一处收尾改动，待重新嵌入最后构建验证。

iOS ARM64 模拟器 Rust 库和 Flutter 应用构建成功。修复了 SwiftPM 与旧硬编码插件链接项重复、iOS 不支持桌面网卡枚举的问题；iOS 唤醒使用 UDP 默认接口，不引入桌面 SystemConfiguration API。模拟器应用已做本地 ad-hoc 签名，尚待启动和远控实测。

最新 Dart 全 lib 分析 0 error，仍有 356 个 warning/info；没有把它表述为零告警。移动输入专项 17 项通过；迁移自有测试已移到上游要求的 `flutter/test/landesk_*_test.dart` 入口。

### 2026-11-05 01:00：iOS 原生实连与输入

- 在专用 iOS 26.5 模拟器运行新基线构建，连接 `192.168.31.199:21218`；客户端要求密码，Mac 端批准后收到真实桌面。没有导入旧凭据。
- iOS 系统键盘可弹出，逐键输入 `ios ok` 后在 Mac TextEdit 实际出现；证据 `.verify/native-runtime/ios-input-on-mac.png`。这是模拟器控制真实 Mac，不是 iOS 真机验证。
- 发现默认虚拟键在窄屏重叠，以及 Scaffold 消耗 viewInsets 后侧栏无法判断系统键盘状态。调整默认键位分行、居中修饰键，改由远控页传入已有键盘可见状态；系统键盘打开时收起侧栏及浮动键，关闭后恢复。新增横竖屏不重叠回归，6 项控件测试通过。修正后仍需重装活验收。
- Rust 最终开发核心编译成功（96 条上游／裁剪遗留警告）；iOS 首轮构建、签名与实际运行成功。构建并不代表 Windows、Linux、Android 验收通过。
- 第一轮 iOS 模拟器已关闭、实例锁已释放；第一轮新 Mac host 已退出。旧版已安装服务未改动。

### 回归影响范围

以官方固定基线为对照：`src/client.rs` 的连接建立只走数值私网 IP；`rendezvous_mediator.rs` 的启动只开本地服务／发现／可选 Web；`common.rs`、`hbbs_http/sync.rs`、`updater.rs` 阻断公网服务入口。`lan.rs` 发现结果改为实际来源地址和端口，`server/connection.rs`、`port_forward_mux.rs` 的转发限制私网目的地。`lib.rs`、`flutter_ffi.rs`、`ui_interface.rs`、`ipc.rs` 接入产品初始化、地址和监听状态。这些改动服务于用户要求的局域网范围，不替换官方认证和媒体协议。

Flutter 连接页、桌面首页与设置页移除公网产品入口；远控页接入自有按键／侧栏，画布模型使用实际可用区域处理旋转；主题和品牌资源保留 LanDesk 外观。Web 网关及前端适配官方消息、密码和权限。平台工程调整名称、包身份和本机开发链接；尚未验证的平台不能标为迁移完成。

### 2026-11-05 01:04：修正候选与环境

- 修正后的 macOS Xcode 构建与开发签名验证成功，重新启动隔离端口 host；Web 临时密码登录通过，初始剪贴板读写按钮均可见，远程画面为 3840×2160，退出正常。未读取系统剪贴板内容。
- 修正后的 iOS 模拟器构建及签名成功；指定 Dart 文件分析 0 error、1 条风格 info。
- Linux `omarchy.local` 无法解析，已知历史地址 SSH 连接超时；未改动任何网络配置。
- 开始在现有 NDK 27.1 工具链构建 Android arm64 原生依赖；截至此条尚无 Android 构建或实连结论。

### 2026-11-05 01:18：iOS 修正候选复验

- 新一次性密码登录通过。核对上游实现：密码在认证成功时立即轮换，不能把前一个浏览器会话使用的密码继续给 iOS；没有修改或绕过该机制。
- 竖屏按键不重叠；虚拟 C、Enter、V 在真实 Mac TextEdit 中产生字符／换行（Mac 当前输入法会显示组合候选）。系统键盘展开时收起自有浮动键与侧栏，关闭后恢复。
- 系统键盘打开状态切到横屏，再收起键盘，真实桌面按横屏可用区域重新适配；回到竖屏正常。证据 `ios-landscape-virtual-keys.png`、`ios-portrait-virtual-keys.png`、`ios-system-keyboard.png`、`ios-landscape-system-keyboard.png`。
- README 换用本次实连截图，继续标注开发候选／模拟器，不指向新发行版。

### 2026-11-05 01:23：Android 构建适配

- 本机已安装 NDK 27.1，而 AGP 默认选择的 NDK 27.0 目录缺失 `source.properties`。工程显式固定 27.1 后继续构建。
- OpenSSL 的交叉 `ranlib` 工具路径已补齐；Rust 首次链接缺少 `ndk_compat`，按 vcpkg 固定基线中的 Google cpu_features 0.11.0 构建，归档 SHA-512 与该基线一致。不是移除依赖或伪造空库。
- Cargo 产品描述、Windows 资源产品名、bundle 名称修正为 LanDesk，保留上游作者与版权。
- iOS 模拟器已关闭；Mac 测试 host 已退出；Ego Lite 本次任务空间已关闭；临时密码文件已删除。Android 后续验证另起所需实例。

Android 原生核心在补齐 cpu_features 后完成链接：188 条警告，退出码 0；`readelf` 确认只依赖 Android 系统库及 `libc++_shared.so`。APK 构建目录已放入本次 `librustdesk.so` 与 NDK 的 `libc++_shared.so`，仍待打包和安装。

### 2026-11-05 01:33：Android 最低系统版本

首次 Gradle 打包在 `DebugMinSdkCheck` 失败：Flutter 3.44.1 要求 API 23，原工程为 API 22。已把应用最低版本调整为 Android 6.0（API 23），不跳过依赖校验；因此 Android 5.1 不在新候选支持范围。NDK 依赖的 API 21 编译目标不代表应用可安装在 API 21。重新打包进行中，尚无 APK 或真机结论。

### 2026-11-05 01:39：Flutter Android 插件兼容

- API 23 检查通过后，发现上游锁定插件仍引用 Flutter 已移除的 Android v1 Registrar。依据各插件 changelog，固定 `flutter_plugin_android_lifecycle 2.0.20`、`file_picker 8.3.6`、`sqflite 2.3.3+2`；没有修改共享 Pub 缓存。
- `uni_links` 的固定 Git 版本也含旧入口，已在 `flutter/vendor/uni_links` 保存来源、许可证和补丁说明，仅删除 v1 注册方法，保留 v2 和 iOS 实现。
- 文件选择器消费入口的 Dart 分析无 error，3 warning 与其余 info 为现有代码问题；退出码 2，不能描述为无告警通过。
- `file_picker` 要求 web 1.x，解析结果同时改变 web、wakelock_plus 与 web_socket_channel 的锁定版本，需纳入跨端回归。此前 Mac/iOS 实连证据仍有效，但不证明本次依赖变更后的候选。Android 尚未打包成功或安装。

### 2026-11-05 01:54：Android APK 完成

Gradle 1 GB 堆在 JetifyTransform 处理 Flutter 引擎时耗尽，调整为 2 GB 后构建成功（313 个任务，4 分 36 秒）。开发 APK 为 `flutter/build/app/outputs/apk/debug/app-debug.apk`，包名 dev.quanru.localdesk、标签 LanDesk、最低 API 23、仅 arm64-v8a；版本 1.0/1 是本地调试默认值，不是发行版本。

合并原生库与 Rust 输出 SHA-256 相同，APK 内 Rust 库与 strip 后文件相同，携带 libc++_shared.so。调试签名验证退出 0（META-INF 条目有签名覆盖警告），证据 `.verify/native-runtime/android-artifact.json`。Redmi 安装返回 INSTALL_FAILED_USER_RESTRICTED，尚未安装或验证连接；正在通过正常界面检查安装设置，不修改系统安全策略。

### 2026-11-05 02:08：Android 模拟器实连

Redmi 重试安装仍返回 USER_RESTRICTED，USB 安装开关原已开启，没有出现可确认提示，未修改安全设置。改用既有 Android 35 arm64 备用模拟器。其旧 LanDesk 版本为 2075，不强制降级或卸载；Debug 新增 `.nativepreview` 包名后缀，保留正式包名及旧数据。独立包构建成功并安装。

- 当前密码认证成功，真实 Mac 3840×2160 桌面通过 AV1 显示；系统键盘逐键输入 `and`、回车抵达 Mac TextEdit，虚拟 C／Enter 也抵达。
- 系统键盘打开时隐藏自有虚拟键与侧栏；收起后恢复；横屏收起键盘后桌面适配正常。
- 横屏键盘打开时，多行快捷键栏遮挡桌面。已改为单行横向滚动，保留全部快捷键，竖屏原布局不变。回归测试通过，修复候选正在重建，不能提前标为活验证通过。
- 证据 `.verify/native-runtime/android-system-keyboard.png`、`android-landscape-virtual-keys.png`、`android-input-on-mac.png`、`android-virtual-input-on-mac.png`。全部 Android 连接证据来自模拟器，非 Redmi 实机。

### 2026-11-05 02:14：横屏键盘修复复验

最新 APK 构建成功（59 秒），覆盖独立 nativepreview 包安装成功。重新以当前一次性密码连接真实 Mac，横屏系统键盘上方的快捷键栏保持单行，桌面仍可见；返回竖屏并收起键盘后，虚拟键与侧栏恢复。截图 `android-landscape-keyboard-fixed.png` 与 `android-portrait-restored.png` 在 `.verify/native-runtime/`。最新目标回归 15 项全部通过，覆盖紧凑栏、默认键位、按住释放、输入浮层。

本轮最终改动面：Android 最低版本／NDK／调试包隔离／Gradle 堆；三个 Pub 插件升级及链接插件 v1 注册入口移除；移动远控快捷键栏在横屏系统键盘显示时采用单行滚动。无需旧数据或协议兼容。`remote_page.dart` 只引入紧凑栏，`remote_page_widgets.dart` 只在横屏键盘可见时选择新布局；竖屏及原始输入方法保留。

模拟器已关闭，Mac 测试 host 已退出，设备锁和 runtime 已释放，临时测试密码已删除。未提交、推送或发布。剩余：本轮插件升级后的 Mac／iOS 重建与回归；Windows／Linux 实际构建与运行；文件／剪贴板／音频／终端／转发完整验收、网络异常与升级覆盖；正式候选包装。当前不能宣布整体迁移完成。

### 2026-11-05 02:24：插件升级后的 Apple 端复验

- iOS／macOS CocoaPods 更新成功。iOS 文件选择器由 SwiftPM 管理后，手写的 DKImagePickerController、DKPhotoGallery、SDWebImage、SwiftyGif 和 file_picker 框架链接声明失效；仅移除三个构建配置中的这些重复声明，保留 SwiftPM 链接和插件实现。
- 更新依赖后的 iOS 模拟器与 macOS Debug 应用均重新构建成功。Mac 打包与开发签名校验通过；iOS 模拟器签名完成。
- 新 iOS 候选以当前密码连接新 Mac 候选成功，系统键盘展开、横屏单行快捷键及真实桌面可见。证据 `.verify/native-runtime/ios-landscape-keyboard-fixed.png`。这证明连接和新布局，不等于文件选择器／SQLite 全功能回归。
- 已请求用户提供可用 Linux 地址与 Windows 环境；现有 Linux 地址不可达，本机未发现 Windows 环境，没有触发远程 CI。其他未验收项仍见当前矩阵：完整文件／剪贴板／音频／终端／转发、网络异常、升级与正式包装。没有把环境缺口或未测功能标为完成。

### 2026-11-05：Mac 与 iPhone 14 Pro 本地安装

用户授权安装到 Mac 与连接中的 iPhone 14 Pro 真机，不含发布。Mac 最新开发包已通过 strict deep 签名校验，替换到 `/Applications/LanDesk.app` 并启动，原用户数据保留；新 host 正在监听 21218。原系统录屏授权绑定旧证书名称，当前新包仍提示缺少权限，通过系统设置刷新时出现本人密码认证，已移交用户，未改写 TCC 或绕过认证。旧 root service 未擅自提权重启。

iPhone 使用独立 iphoneos 原生依赖和 `aarch64-apple-ios` Rust 核心，核心构建成功（2 分 16 秒）。固定 Rust 标准库下载 SHA-256 为 `7362a6629e09c0d3c8723809217b80a425d5f9466ff312fcf02245050168e116`。签名团队从上游残留修正为 `62S977T8M3`，包名 `dev.quanru.localdesk` 不变；移除未使用的推送和 Wi-Fi SSID entitlement，保留局域网权限说明。为目标设备及现有开发证书创建本地开发 profile，不上传 TestFlight。Flutter Release UI 正在打包，以便脱离调试器启动；尚未宣称安装成功。

真机 Release UI 构建成功，主应用及框架分别完成开发签名，strict deep 校验通过。签名有效期至 2027-11-05，版本 1.5.1（69），仅本地开发候选。通过设备锁下的 devicectl 安装到 iPhone 14 Pro 成功，并在无调试器附着状态启动成功；安装、启动与产物证据为 `.verify/native-runtime/iphone-install.json`、`iphone-launch.json`、`iphone-device-artifact.json`。当前尚未在该真机完成 Mac 远控，因为 Mac 屏幕录制授权仍待用户本人认证。

真机首次安装后仅有白屏，不能把 devicectl 的启动成功当作可用验收。检查 Release 可执行文件发现动态 FFI `wire_*` 导出入口缺失：Swift 调用生成头文件的保留函数时丢弃了返回值，Release 优化消除了引用。新增独立 `NativeBridgeAnchor.m`，将生成函数返回值写入 volatile 变量，使入口引用在优化后仍保留；不修改生成文件，也不关闭整个应用的优化或死代码裁剪。修复候选重建与实机复验进行中。

修复版 Release 构建与签名通过，生成头文件引用的 326 个桥接入口在最终可执行文件中全部存在（`iphone-bridge-symbols.json`，绑定 SHA-256）。覆盖安装到同一 iPhone 14 Pro 成功，无调试器启动后首页正常显示，白屏已消除；截图 `.verify/native-runtime/iphone-installed-home.png`。这是真机证据，不是模拟器截图。Mac 录屏权限仍等待用户认证，不能宣称本次真机远控已验收。

iPhone 已通过系统联网授权，首页地址填入 `192.168.31.199:21218`，未发起连接。使用第三方输入法时自动化默认 Input 路径超时，改用 typeOnly 后成功；这是自动化输入方式问题，不把它记录为远程虚拟键盘验证。Mac 的本人认证仍未收到完成确认，本次不继续操作该认证框。

### 2026-11-05 09:14：iPhone 真机连接确认

用户完成 Mac 系统权限认证后，新进程继续监听 TCP 21218，LanDesk 不再提示录屏权限缺失。iPhone 14 Pro 当前已在横屏远控会话中显示真实 Mac 桌面；Esc、Tab、方向、C/V、空格、Enter、回退和 Ctrl/Opt/Cmd 悬浮键可见，右侧虚拟按键入口已开启。本轮确认画面与按键可见，不冒充所有键位输入的完整回归。保留会话交给用户试用，设备锁在截图后释放。

### 2026-11-05：用户参考图默认键位

默认布局改为 Esc 左上、滚轮左侧中部、Ctrl/Opt/Cmd 左下、T/C/V 右侧竖排、鼠标右键与 Space/Enter/Back 右下。T 按字母键处理，移除默认 Tab 和上下方向键；编辑器仍可添加这些键。底部右侧按固定间距靠右，右侧列按固定垂直间距排列，竖屏修饰键另起一排避免重叠。默认锚点随拖动转为用户坐标并正常保存；已有自定义文件不被自动覆盖，恢复默认使用新布局。新增右键按钮调用既有受权限检查的鼠标 tap 路径。

定向 widget 回归 6 项通过，覆盖两种方向下全部键与滚轮/右键的防重叠、布局保存、组合键释放及重置相关交互。iPhone 本地候选重建中，尚未标记截图验收完成。

真机 Release 构建、签名与覆盖安装成功，iPhone 14 Pro 重新连接真实 Mac 后已显示新默认布局，无需覆盖用户保存文件。截图 `.verify/native-runtime/iphone-reference-default-layout.png`：左上 Esc、左侧滚轮、左下修饰键、右侧 T/C/V、右下右键/Space/Enter/Back 均可见且互不重叠。安装回执 `iphone-layout-install.json`。保留当前连接供用户试用；未提交、推送或公开发布。

### 2026-11-05：窗口总览遗漏与连接按钮裁切

逐文件核对用户指定提交 `74e43f92f8f9917727d00342161b855a6798ea6f`：窗口总览 Flutter UI、Mac Ctrl+Up / Windows Meta+Tab 与 Linux 自定义绑定已迁入，但 enigo 的 macOS 方向键标记修复遗漏。现已补回箭头键的 SecondaryFn/NumericPad 标记，保持 ignore_flags 与 F11 原逻辑。为满足文件规模要求，仅把事件发送与输入 trait 实现抽入同模块 include 文件 `input_events.rs`，无协议变化。

桌面连接按钮的 28 高固定容器与主题上下 20 内边距冲突，导致中文文字被裁切。改为由主题与文字缩放决定按钮高度，下拉按钮同步至少 40；连接操作区域拆至 part 文件，主页面降到 600 行以下。定向回归 6 项通过，包含中英文 100%/150%/200% 文字尺寸和窗口总览快捷键/配置。Mac 重建与实连验证尚在进行。

Mac 原生核心与 Flutter Debug UI 构建成功，strict deep 签名验证通过，以相同 designated requirement 覆盖安装 `/Applications/LanDesk.app`，保留用户数据。已安装产物哈希见 `.verify/native-runtime/mac-overview-installed.json`。真实窗口截图 `mac-connect-button-fixed.png` 确认“连接”文字完整显示。

iPhone 14 Pro 实连中观察到真实 Mission Control 多窗口缩略图，截图 `iphone-window-overview-observed.png`。重复收起/展开的因果验证仍受其他桌面会话持续切换窗口干扰，不能仅凭该截图宣称快捷键稳定验收；已请求短暂独占人工/桌面自动化操作时间。未提交、推送或发布。
