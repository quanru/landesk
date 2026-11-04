# 第四批 RustDesk 安全修复

日期：2026-11-04。源码基线 `ab54f13715da721def8824186c27934af18c0688`；RustDesk 对照固定为 `55786aaa5709ac0a450aabcf06f9d1fee3119908`。本批适配 4 项，累计 32 项；尚有 3 项 Windows 安装器安全优先项，另有 154 项暂缓差异，未宣称全部追平。

## 来源与实际改动

| 上游提交 | 原作者 | 处理范围 |
| --- | --- | --- |
| `08affc69c426396557665eef0e2fb0a8831debd7` | RustDesk | 文件剪贴板范围读取按无符号线字段解码，单次上限 16 MiB；列表加随机 nonce 和 ID，绑定实际收到该列表的连接；保留有限的旧列表以支持复制新文件后继续传输；Windows 坐标计算用 i64 并限制到合法范围。 |
| `13e1278b4c46eadede9546d3ada1ff9d94b593dd` | RustDesk、Claude Opus 5.5 | 自动登录由受控端在输入前检查登录／锁屏状态；状态查询失败则不输入。Windows 7／Server 2008 R2 的反向锁屏标志单独处理，不以残留 LogonUI 进程判断锁屏。 |
| `5278fcab685723099e9950d56cb605807db5aa2a` | fufesou、rustdesk、Claude Fable 5.1 | 收到游标后先校验尺寸和热点，再有界解压；源尺寸最多 512×512，RGBA 长度必须准确，压缩输入也有上限；适配 DPR、透明度、缩放后栅格与热点，Linux 补正方形画布。 |
| `e9ddbd8f460dac1b30b9815ba324a5dadc8d97b0` | RustDesk、Claude Opus 5.5 | 按内容命名和去重游标；Flutter 通过字节事件接收像素，停止用 JSON 数组及窗口重放列表积累图片；限制已解码图片缓存，必要时从核心恢复；服务端句柄数及压缩形状字节量达到阈值时重建缓存。 |

保留原许可、RustDesk 与 SubnetDesk credit。未引入上游 CI 或旧版 Sciter UI；LanDesk 已无这些 Sciter 文件。下载与网络策略未恢复到公网模式。

## LanDesk 专属适配

- 现有 `Message` 的 33／34 是 LAN 握手，35 是端口转发，不能照搬上游编号。新增 `os_login` 使用空闲的 36，序列化回归检查确认 33—35 不变。
- LanDesk 版本仍为 1.3.0，不能用 RustDesk 1.5.1 判断对端能力。服务端在 Windows／macOS 的 PeerInfo 中明确声明 `landesk-os-login-v1`，客户端仅在能力为布尔 true 且平台匹配时启用自动登录。
- 对旧版、未知或 Linux 对端跳过自动登录，不回退到直接往当前焦点窗口输入密码；手动 OS Password 入口保留。新消息仅允许已认证的远程控制会话，仍受键盘权限检查约束。
- 保留 LanDesk 已有的客户端旋转、输入映射及 Linux 系统游标恢复。旋转纳入原生游标缓存键，先旋转图像及热点，再做 Linux 画布补齐。
- 游标核心逻辑放在 `src/client/cursor.rs`，新增回归按职责拆文件；剪贴板测试与生产实现分离。新声明 zstd 0.13 依赖，复用锁定的 0.13.1；xxhash-rust 固定为上游使用的 0.8.19。未更新其他包。
- 本批没有再改 common 的 gitlink，仍为本地 `2e7979e8bbd88b481457e012531d3e07017f9799`。后续推送仍须先推 common 再推应用。

## 验证结果

编译与测试使用本机 dev-gate heavy；轻量门禁用 light，内部并发沿用 2。沿用第三批 Rust 1.82.0、Flutter 3.44.1、FRB 1.80.1 和隔离 native 验证依赖，无远端 CI。

| 验证 | 结果与覆盖 |
| --- | --- |
| `cargo test --locked -p clipboard --lib --features unix-file-copy-paste -- --test-threads=1` | 29 个通过。真实 Mac 临时文件覆盖有符号范围解码、读取上限、列表连接绑定、旧列表传输、同元数据重新复制及文件被替换后的拒绝。 |
| `python3 tools/localdesk/test-lan-security.py` | 20 个通过。编译实际 LAN 协议、admission、能力判断及实际守卫输入方法；新增协议字段兼容、未知／错误能力、未锁屏或查询失败不输入、锁屏时输入、Windows 锁屏标志解释和坐标极值检查。OS 状态与输入 sink 为替身，不执行真实密码输入，也不代表 Windows API 验收。 |
| `cargo test --locked --lib --features flutter,unix-file-copy-paste client:: -- --test-threads=1` | 实际应用宿主 18 个定向测试通过。包含有界游标解压、畸形尺寸和热点、压缩炸弹、内容去重、缓存形状恢复，以及真实 TCP 验证登录前剪贴板丢弃、认证消息通过、登录后剪贴板通过。另覆盖既有本地凭据元信息与截图错误保留用例。 |
| 应用宿主 `os_login_is_scoped_to_authenticated_remote_control` | 1 个通过。新消息在远程控制中允许，在文件传输／终端／摄像头／端口转发会话中拒绝。 |
| 应用宿主 `cursor_shape_tests`、`a_cursor_content_id_fits_a_web_client_number` | 各 1 个通过。形状内容去重、复用、句柄／字节阈值与 53 位 ID 兼容。 |
| Flutter 定向回归 | 游标尺寸、默认游标、缓存重放、已有初始化及第三批下载回归共 57 个通过（含 1 个最小预览）。旋转缓存键最后适配后，对受影响的三个游标测试文件再跑 52 个，全部通过。 |
| FRB 本地生成、原生宿主编译 | 成功。实际 Mac 应用测试编译并链接通过，69 条 Rust 警告；不宣称零警告或所有警告均为既有。生成文件仍遵循仓库忽略规则，未提交缓存或工具链。 |
| LAN 残留、Flutter 工具链、`git diff --check` | 通过。 |

原生组件测试中曾发现第三批 admission 测试缺少 Tokio 模块导入，已补齐，避免只在临时 harness 中可编译。上游 loopback 测试的 Stream 类型和 connect API 也已适配本地 common。一次权限测试的过滤路径未匹配到测试，已纠正过滤并确认实际执行 1 个；零用例不计作通过证据。

截图：`/tmp/landesk-security-20261104-batch4/cursor-rotation.png`。这是 Flutter 最小测试预览：通过真实游标生成逻辑取得 0°／90°／270° 的 PNG 和热点，以 3 倍显示便于核对。原生注册通道为测试替身，输入像素为合成图，不是远程桌面会话、系统原生游标截图或官网素材。已目视核对。

日志位于 `/tmp/landesk-fourth-final-components.log`、`/tmp/landesk-cursor-native-tests.log`、`/tmp/landesk-os-login-scope.log`、`/tmp/landesk-server-cursor-cache.log`、`/tmp/landesk-final-flutter-regressions.log` 和 `/tmp/landesk-cursor-final-cache-tests.log`。

## 尚未覆盖的范围

- Windows／Linux 原生构建、真实文件剪贴板与 OS 自动登录、移动端或浏览器远程会话尚未验收。本批 Mac 构建不能证明 Windows C／COM／WTS 或 Linux FUSE 的运行结果。
- 缓存修复限制了 Flutter 已解码图片及服务端部分缓存；核心会话仍保留压缩形状，原生游标也没有按所有平台统一的 LRU。不能宣称整个会话内存已彻底有界。
- 未修复或验收此前虚拟键盘显示和整个远程画面的旋转问题。此次旋转回归仅覆盖游标生成与现有旋转适配。
- Windows 安装器的 `402ed07b0`、`f705902ec`、`2b6fedfc8` 仍未接入。它们涉及提权交接、受保护临时目录、服务控制及更新器关联改造，需要按依赖顺序适配，并在真实 Windows 上验证标准用户／管理员、特殊字符路径、安装失败恢复、更新及卸载；不能只复制脚本就算完成。

本轮只在本地 main 准备候选和提交，没有推送、安装／替换应用、发布安装包或 TestFlight，也没有部署官网。

候选源码指纹：`7b3a329c2cb59a46fa67545f81967aef91491ecfaeb28250acdb9fe7b7ccc959`。按修改的 35 个 src／libs／flutter/lib／Cargo 文件路径排序，对逐文件 SHA-256 的 JSON 再取 SHA-256；这是候选内容记录，不是全平台验证或发布 attestation。
