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
