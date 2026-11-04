# RustDesk 上游修复移植

2026-11-04，根据用户要求选择性接入 RustDesk 改动。本轮针对内存生命周期和剪贴板稳定性、权限检查，不做全量上游同步。

## 基线与来源

- LanDesk 本地基线：`74e43f92f8f9917727d00342161b855a6798ea6f`。开始时先快进接入远端已有的窗口概览修改，未覆盖 README 来源说明的未提交修改。
- RustDesk 核对版本：`55786aaa5709ac0a450aabcf06f9d1fee3119908`（2026-11-03）。
- 共同祖先：`5abf4e9724dc9a8c9b45dfe13e71af11616eb2c8`（2026-07-16）。RustDesk 一侧有 377 个不在 LanDesk 祖先链上的提交；这个数字不表示 377 项功能都缺失，SubnetDesk 已移植过其中部分修复。
- 从官方 `https://github.com/rustdesk/rustdesk.git` 拉取历史，仅更新本地远程跟踪引用。未合并整个分支、修改子模块指针、触发远程 CI 或发布应用。

## 本轮接入

| RustDesk 原始提交 | 原作者 | 接入内容 |
| --- | --- | --- |
| [`f9586e171427`](https://github.com/rustdesk/rustdesk/commit/f9586e171427c1b078b4f3fe81a5729a5d21aa5c) | ignat10 | Android 按序列化 Parcel 大小限制剪贴板；回收 Parcel；捕获系统写入异常，成功后才更新同步记录。 |
| [`41f182e636ba`](https://github.com/rustdesk/rustdesk/commit/41f182e636ba7c5072df9fac9abf4cea197e20f2) | Victor Lamers | Android 回调内复制视频／音频数据，避免 Image／ByteBuffer 释放或复用后继续读取外部指针。 |
| [`55786aaa5709`](https://github.com/rustdesk/rustdesk/commit/55786aaa5709ac0a450aabcf06f9d1fee3119908) | RustDesk | 配套使用缓冲区交换，避免修复后每帧复制两次；启停采集时释放持有的帧。 |
| [`4b92080e3e09`](https://github.com/rustdesk/rustdesk/commit/4b92080e3e0970cace2ece563498c64be2dbae6c) | Leo Camus | X11 枚举显示器期间保留 RandR reply，切换屏幕或销毁迭代器时才释放，修复释放后使用。 |
| [`f299fb990600`](https://github.com/rustdesk/rustdesk/commit/f299fb9906006247863250d7dfaa016f29eef7a4) | RustDesk | 文件剪贴板逐条检查 Unix 文件传输权限；单向传输时拦截对主机文件列表和内容的主动读取请求。 |

上述补丁直接应用原始差异，保留现有许可和版权声明。第二项与第三项按依赖顺序接入，最终 Android 帧实现与第三项的上游版本一致。其余三项已检查可反向应用原始补丁，确认没有额外混入改动。

## 本轮不接入的范围

- 公网会合、WebSocket／WebRTC、中继、云账号、地址簿和在线更新流程：不符合 LanDesk 的局域网定位。
- `5882346caa` 音频声道校验、`b1fad7bbed` RGBA 尺寸校验、`59fdda383` 越界文件确认修复和 `92d787b88` 剪贴板特殊格式修复：现有代码已包含对应补丁，反向应用检查通过，不重复修改。
- `5b4d6baf4` 的 `BackingScaleFactor` autoreleasepool 修复：当前代码已无该函数，不机械恢复已移除实现。
- 自动登录密码处理、trusted-device V2、自动 FPS、游标与文件剪贴板的大范围改造：需要协议／依赖及多个平台的额外验证，本轮没有接入。它们仍需后续单独评估，不能把本轮结果理解为完整安全审计或全部上游修复已同步。
- 移动端浮动鼠标、语言选择及 iOS 生命周期／音频等改动：本轮优先处理上述稳定性和权限问题，未扩大到这些交互行为。此前的虚拟键盘显示和旋转问题仍未在本轮修复或验收。

## 验证

新增 `tools/localdesk/test-upstream-backports.py` 与 `tools/localdesk/upstream-tests/`。脚本从工作区或指定 Git ref 提取实际生产实现，编译后运行；测试夹具只替代系统边界，不复制一份待测算法。

- Rust 1.82.0：8 个用例通过。覆盖回调数据被复用、下一帧不破坏当前编码数据、无效／超时／启停状态、X11 部分遍历／完整遍历／提前销毁、单向文件请求分类、会话中关闭传输权限。
- Kotlin 2.1.0／JVM：普通剪贴板写入、超过 800 KiB 拒绝、恰好等于上限、Binder 写入异常后状态保留、重试成功及 Parcel 回收检查通过。
- 对合入前 `74e43f92f` 的反向验证：frame、x11、clipboard 三组均成功编译，随后在断言阶段复现原问题。日志：`/tmp/landesk-upstream-negative-controls.log`。
- `scripts/check_lan_only_residuals.sh`、`check_localdesk_branding.sh`、`check_linux_service_branding.sh`、`check_flutter_toolchain.sh` 全部通过。检查前初始化了固定版本的 `libs/hbb_common`，其提交仍为 `262dd7619b3da8ec87f3d7a1bb59762eb782ea65`。
- `git diff --check` 通过。

所有编译使用本机 `dev-gate` heavy 名额，定向脚本检查使用 light 名额。临时编译器存放 `/tmp/landesk-upstream-tools/`，不进入 Git；Rust 编译器和标准库归档已按官方 manifest 核验 SHA-256。测试产物使用临时目录，退出后删除。

重跑组件测试（需已有 Rust 和 Kotlin 编译工具）：

```sh
~/.local/bin/dev-gate run --kind heavy -- \
  python3 tools/localdesk/test-upstream-backports.py \
  --rustc /path/to/rustc --sysroot /path/to/rust-sysroot \
  --java /path/to/java \
  --kotlin-classpath '/path/to/kotlin-jars/*' \
  --kotlin-stdlib /path/to/kotlin-stdlib.jar
```

这些是组件回归测试。X11 FFI、Android Parcel／Binder 和协议类型使用测试替身；文件传输测试编译的是实际请求分类函数和权限条件，未启动远程会话。当前没有完整 Flutter SDK／原生依赖构建环境，本轮未完成全端应用构建、Android 真机采集、真实 Binder 事务、Linux X11 会话或跨端文件剪贴板验证。没有对虚拟键盘、旋转、现有安装包或 TestFlight 状态作新的成功声明。

本轮仅本地源码接入，不推送、不发版。后续发布前应完成受影响平台的原生构建与真实会话验证。


## 第二批：扩大核对与接入范围

用户指出首批 5 项不足后，继续核对全部 377 个上游提交，并追加 20 项接入。首批只解决了一组优先问题，不代表剩余差异已全部处理。完整列表见 [逐提交清单](rustdesk-upstream-audit-2026-11-04.md)。其中的“已有移植记录”只说明可追溯到对应实现，不等同于整份补丁逐行一致；“暂缓”和“优先待移植”均不是完成状态。

第二批源码从 `d69ea4261` 准备，受影响的 12 个生产文件按路径排序、逐文件 SHA-256 生成 JSON 后的总指纹为 `49efd7e81446b7aa00f6e51b7f04b4ebe51a8f5619f3e53e8087d7e608e942cd`。文件集合为 Cargo.lock、PipeWire 实现及 src 下 client、io_loop、flutter、flutter_ffi、ipc、lang、gtk_sudo、linux、audio_service、wayland；不包含此前 README 的未提交来源说明。

| RustDesk 提交 | 原作者 | 接入内容 |
| --- | --- | --- |
| [`0cbeb0473`](https://github.com/rustdesk/rustdesk/commit/0cbeb0473099f813c32077d446fef513061b3973) | Chris21x | 向 Linux 用户态服务透传已有 PulseAudio／PipeWire 延迟环境变量，不制造默认值。 |
| [`bd9262397`](https://github.com/rustdesk/rustdesk/commit/bd9262397208c509ea97af61f0d44621ef25611c) | Leo Camus | 从行首匹配 xrandr 输出名，避免 DP-1 误匹配 eDP-1。 |
| [`106f700be`](https://github.com/rustdesk/rustdesk/commit/106f700be4a9a924a60e29783520cd43a7811239) | Lukas | 识别 Debian 的 gdm3/daemon.conf。 |
| [`01e1323e5`](https://github.com/rustdesk/rustdesk/commit/01e1323e51d998084698a1b1e09b42040bda157d) | Lukas | 分辨率列表遇到隔行模式后继续解析后续逐行模式。 |
| [`21c488b6c`](https://github.com/rustdesk/rustdesk/commit/21c488b6ce80159484015dfd0f58ef7748a24f6c) | Lukas | 按 passwd 的 shell 字段识别常见 greeter shell 路径，避免匹配用户主目录。 |
| [`3ec041644`](https://github.com/rustdesk/rustdesk/commit/3ec041644d6c18a6fbf8b8291bf60ef71614e513) | RustDesk | 修正 GTK sudo 的错误提示和 sudo-rs 重试状态。 |
| [`68a35e65f`](https://github.com/rustdesk/rustdesk/commit/68a35e65f228244ebdb5d4ce3ad386eca8292672) | RustDesk | Unix 原生 Flutter 入口忽略 SIGPIPE，避免断管导致进程退出。 |
| [`c8a4e0680`](https://github.com/rustdesk/rustdesk/commit/c8a4e0680cb553b5547cfccfb859316688078cd6) | Lukas | 远程系统音频优先采集默认输出设备的 monitor；失败时保留原回退。 |
| [`8814503e0`](https://github.com/rustdesk/rustdesk/commit/8814503e06a63431ea6d16b1c24ec40ee1a84a21) | Lukas | 固定 pulsectl 的默认音源修复提交。 |
| [`851d2df88`](https://github.com/rustdesk/rustdesk/commit/851d2df88cc8ef7a8368f74e8b2e7254861ee00a) | RustDesk | 修复音频 IPC 断开／读取失败后的忙循环及语音通话转发空转。 |
| [`e4b9594c5`](https://github.com/rustdesk/rustdesk/commit/e4b9594c5ee688f63a607f1742816def0b634e46) | Vojtěch Lapuník | Android 与 iOS 均不强制固定 64 帧音频缓冲区。 |
| [`e5bc204fe`](https://github.com/rustdesk/rustdesk/commit/e5bc204fe4dacc4db9c3cdb1f1338813986c89e7) | Zixun LI | PipeWire 捕获不使用时钟等待陈旧时间戳，避免耗尽合成器缓冲。 |
| [`4411d10f4`](https://github.com/rustdesk/rustdesk/commit/4411d10f450a514c01c83e4f8af7151836300abb) | RustDesk | Flatpak 以当前进程用户作为活动用户，避免依赖容器外 loginctl。 |
| [`beeeef14f`](https://github.com/rustdesk/rustdesk/commit/beeeef14f0a61bd622aacf042b4396bdeaed9b61) | rustdesk | 适配现有 Wayland 阶段错误逻辑，透传无法分类的实际错误。 |
| [`182356ee8`](https://github.com/rustdesk/rustdesk/commit/182356ee8bbcb3a3c19754687660eb0d0404b0b6) | Minh Nguyen | 适配 LanDesk 的本地最近设备与收藏读取：桌面不受 APP_DIR 未设置影响，移动端仍保留保护；不恢复云地址簿。 |
| [`25d274227`](https://github.com/rustdesk/rustdesk/commit/25d27422733920926cff0c27f8e37f8fdbd26288) | Lukas | 系统 kk／ka locale 映射到现有 kz／ge 翻译表。 |
| [`f7b0af78c`](https://github.com/rustdesk/rustdesk/commit/f7b0af78cbbfc90aa5403fbace93b4fa99c1abbb) | Lukas | 香港、澳门和 Hant locale 选择繁体；保留用户明确选择及现有 CJK 回退。 |
| [`91c9fccbb`](https://github.com/rustdesk/rustdesk/commit/91c9fccbb0f7bfe5f11644d5fbdec9b23fa10540) | changshenhan | 仅接入 bytes 1.11.1、crossbeam-epoch 0.9.20；quinn 已被移除，不恢复它。 |
| [`3202d1764`](https://github.com/rustdesk/rustdesk/commit/3202d1764c58902db8c97d803f1f63fa7cbf9e45) | Shaan Majid | 升级 rustls-pki-types 1.15.1、rustls-webpki 0.103.16 和 webpki-root-certs 1.0.10。 |
| [`f96a44a01`](https://github.com/rustdesk/rustdesk/commit/f96a44a0190e5e5ad79ceed298efbbc7a58a03db) | github-actions[bot] | 将 webpki-roots 更新到上游固定的 1.0.11。 |

### 第二批验证与限制

- `test-upstream-platform.py`：14 个用例通过，包括生产 xrandr 解析、greeter shell 判断、Flatpak 用户选择、桌面配置路径、语言选择和音频延迟变量。系统边界使用测试替身，不操作真实用户配置。
- 6 个升级后的 registry 依赖在 Rust 1.82.0 下编译并运行基础调用；其版本、registry 来源和 SHA-256 与应用 Cargo.lock 一致。没有使用比应用锁定版本更新的 zeroize，以免引入 Rust 2024 edition 要求。
- 用 syn 解析全部 11 个修改的 Rust 生产文件，语法检查通过；这不代替各平台条件编译和链接。
- `check_lan_only_residuals.sh`、`check_flutter_toolchain.sh`、Python 脚本语法及 `git diff --check` 通过。
- 本轮没有修改 Flutter 皮肤、虚拟键盘、旋转、连接认证协议或固定的 landesk-common 子模块提交。未构建安装包、未推送、未部署、未更改 TestFlight。
- 尚未验证：真实 PulseAudio／PipeWire、GTK sudo、Linux 登录屏幕／Flatpak、完整 Rust／Flutter 应用及跨平台运行。这些接入不能冒充已经进入用户安装包。

同时只读拉取 SubnetDesk `bb97b0e5f7c383141dd3bf86ca9c673aac7b5df0`（2026-11-02），确认其在原基线之后进入 2.0，包括新 UI、用户会话运行时及 Windows 适配；未把整条分支合入 LanDesk。维护时应分别跟踪 RustDesk 通用修复和 SubnetDesk 局域网底座，保留 LanDesk 的移动端与品牌差异。


第二批清单统计：25 项为本次两批接入，14 项存在等价补丁，23 项有移植记录，3 项已有对应实现；106 项是本轮不接入的上游文档、翻译或 CI 内容，36 项涉及已移除流程，6 项被上游撤回／替代。其余 **164 项仍暂缓，其中 10 项是安全优先队列**。这些是提交分类数量，不是独立缺陷数量；不能宣称 LanDesk 已完整追平 RustDesk。

当前本地注册了 `rustdesk` 和 `subnetdesk` 两个只用于拉取的上游 remote，`origin` 仍为 quanru/landesk；新克隆需自行添加这些本地 remote。后续核对流程为：拉取官方上游、运行 `tools/localdesk/audit-upstream.py`、按依赖移植、运行相应组件和目标平台检查，再更新清单。脚本不自动修改源代码或触发远程 CI。


第二批锁文件核对补充：最初从 RustDesk 拷入的 rustls-pki-types 条目包含本工程没有启用的 `web-time` 依赖边，完整 `cargo metadata --locked` 检查识别出锁文件需要更新。已让 Cargo 重新解析该条目并移除不适用的边，保留原有 cfg-if 和宏工具依赖版本，避免无关升级。随后 `cargo metadata --offline --locked` 到达依赖包读取阶段，但因本机缺少 `ab_glyph 0.2.31` 等原有缓存而退出，**完整 metadata 检查未标为通过**。6 个实际升级依赖的组件编译、来源及哈希核对已通过；完整应用构建仍待后续目标平台验证。

## 第三批安全修复

继续接入下载目标保护、未认证连接资源限制与登录前剪贴板保护，并补齐 Mac 整应用宿主检查。范围、依赖指针和测试边界见 [第三批验证记录](security-backports-2026-11-04.md)。本次新增 3 项，累计 28 项；其余差异仍按逐提交清单保留。
