# 原生迁移开发构建

主线 `main`（迁移来源 `migration/rustdesk-native`），固定上游见 `../migration/native-baseline.json`。本目录只构建开发候选，不上传、发布或更改 `/Applications`。验证进度见 `docs/validation/native-migration-progress-2026-11-04.md`。

工具链：Rust 1.82.0、Flutter 3.44.1、flutter_rust_bridge_codegen 1.80.1、CocoaPods、Xcode。原生依赖来源参考项目 `res/vcpkg`；本轮移动端开发验证使用的源码归档与校验值记录在 `development-dependencies.json`，不作为发行依赖锁定结果；iOS 模拟器与真机的库不能混用。所有构建通过本机 `dev-gate`，内部编译并发为 2。上游 `build.py` 和自动发布工作流仍包含 RustDesk 包装约定，不能作为 LanDesk 发布入口；本次没有验证 Windows／Linux 安装包。

## 通用生成步骤

在 `flutter` 运行 `flutter pub get`。在根目录运行固定版本的生成器：

```sh
flutter_rust_bridge_codegen --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/ios/Runner/bridge_generated.h \
  --extra-c-output-path flutter/macos/Runner --skip-deps-check --no-build-runner
(cd flutter && dart run build_runner build --delete-conflicting-outputs --build-filter=lib/generated_bridge.freezed.dart)
```

内置浏览器远控已移除，构建不再需要 Bun 或 Web 资源。FRB 生成需要本机 `cargo-expand` 及完整的 Cargo 依赖缓存；离线缓存完整时可设置 `CARGO_NET_OFFLINE=true`。

## macOS

```sh
cargo build --locked --lib --bin service --features flutter
(cd flutter && flutter build macos --debug --config-only --no-pub)
```

Xcode 使用 `flutter/macos/Runner.xcworkspace` 的 `Runner` scheme；开发 Rust 库需传 `RUSTDESK_TARGET=debug`，并使用绝对 `OBJROOT`、`SYMROOT`，`-jobs 2`。正式配置默认读取 release Rust 库。若本机 Homebrew libaom 引用 VMAF，设置 `LANDESK_LOCAL_VMAF_DIR=/opt/homebrew/lib`；这只是本机开发依赖，不是发布依赖锁定方案。

Xcode 构建后，用 `package-macos.py <app> --service target/debug/service --identity <本机开发证书>` 打包本机 dylib 并验证开发签名。此步骤不公证、不安装、不发布。开发运行也要持有 runtime 额度。

## iOS 模拟器

```sh
cargo build --locked --lib --features flutter --target aarch64-apple-ios-sim
(cd flutter && flutter build ios --simulator --debug --config-only --no-codesign --no-pub)
```

为目标配置模拟器 SDK、独立的 `VCPKG_ROOT`、模拟器 libsodium 与 Rust 标准库。不能链接 Homebrew 的 macOS 库。工程按 SDK 选择 `LANDESK_RUST_TARGET`；调试库需传 `LANDESK_RUST_PROFILE=debug`，默认 release。用 `Runner.xcworkspace`，`-sdk iphonesimulator`、`-jobs 2`、`CODE_SIGNING_ALLOWED=NO`、`DEAD_CODE_STRIPPING=YES`、`ENABLE_DEBUG_DYLIB=NO` 构建。设备运行按当前设备锁规则执行；构建成功不是运行验收。

## 配置隔离

macOS 新配置为 `~/Library/Preferences/dev.quanru.LanDesk/`，旧 LocalDesk 配置不导入。验证可以给新配置设独立 `direct-access-port`，不要占用已运行旧版的端口。原生端口默认 21118。

原生直连不加密，保持官方密码或被控端批准及权限检查；需要传输加密时搭配 Tailscale／VPN。

## Android arm64

开发工具链使用 NDK `27.1.12297006`、JDK 17、Gradle 8.11.1。应用最低 Android 6.0（API 23），与 Flutter 3.44.1 的最低要求一致；本地原生依赖以 API 21 编译不改变应用安装下限。Gradle 工程固定 NDK 版本，避免使用本机不完整的默认目录。Rust 目标为 `aarch64-linux-android`，设置目标专用 `CC`／`CXX`／`AR` 与 Cargo linker；OpenSSL 安装阶段还需要目标 `ranlib`（NDK 的 `llvm-ranlib`）。

原生依赖除 Opus、VPX、AOM、libyuv、libsodium 外，还要按 `vcpkg.json` 基线构建 `cpu-features`，其 `libndk_compat.a` 是 Android 链接依赖。先编译 Rust，再把 `liblibrustdesk.so` 以 `librustdesk.so` 名称放入 `flutter/android/app/src/main/jniLibs/arm64-v8a/`，并携带所需的 `libc++_shared.so`；验证 APK 的 ABI 与实际动态依赖后再安装。单纯生成 Flutter APK 不代表已包含新 Rust 核心。

这套本地 Debug 候选不启用 `hwcodec`，不用于证明 Android 硬件编解码／被控能力或正式发行可用。Gradle 使用 `--no-daemon --no-parallel --max-workers=2`，构建受 heavy 额度限制；真机操作另取 `device-android` 锁。

Flutter 3.44.1 已移除 Android v1 注册接口。`pubspec.yaml` 固定兼容的生命周期、文件选择器和 SQLite 插件；`vendor/uni_links/LANDESK-PATCH.md` 记录链接插件的来源与最小补丁，不修改共享 Pub 缓存。依赖变化需要重新验证各端，不能复用旧候选的运行结论。Gradle 堆上限为 2 GB，避免处理 Flutter 引擎 JAR 时在 1 GB 限制下耗尽内存；内部仍限制两个 worker。

## iPhone 真机本地试用

真机使用 `aarch64-apple-ios`，原生依赖必须以 `iphoneos` SDK 独立构建；不能复用模拟器静态库。先完成 `cargo build --locked --lib --features flutter --target aarch64-apple-ios`，再构建 `Runner.xcworkspace` 的 Release 配置，传 `LANDESK_RUST_PROFILE=debug` 可链接开发核心。Release Flutter UI 可以脱离调试器启动，不等于对外正式发行。

签名团队为 LanDesk 自有的 `62S977T8M3`，包名保持 `dev.quanru.localdesk`。开发 provisioning profile 必须包含目标手机及本机证书；不要把 `PROVISIONING_PROFILE_SPECIFIER` 作为全局 Xcode 参数传给所有第三方资源包；本地候选可先以 `CODE_SIGNING_ALLOWED=NO` 构建，再用匹配 profile 嵌入主应用并分别签名 Frameworks 与主应用。必须执行 strict deep 签名校验。不把配置文件或私钥提交到仓库。应用未使用推送注册或 Wi-Fi SSID 读取，故移除上游这两项多余 entitlement。局域网权限说明仍保留。

安装使用已授权真机的设备锁和 `xcrun devicectl device install app`，保留应用数据，不卸载现有版本。安装完成核验签名、设备上的版本及脱离调试器启动；这不上传 App Store Connect 或 TestFlight。

真机 Release 构建必须保留 Dart 动态查找的桥接导出。`Runner/NativeBridgeAnchor.m` 以 volatile 写入保留生成头文件的入口引用；不要改回丢弃返回值的 Swift 空调用，否则优化构建会白屏。签名后可用 `nm -gU Runner.app/Runner` 检查生成头文件引用的全部入口；2026-11-05 本地候选 326 个入口完整，并在 iPhone 14 Pro 真机验证首页正常启动。

### macOS 启动服务标识

启动服务统一使用 `md.lifeos.LanDesk_service` / `md.lifeos.LanDesk_server`。
这与应用 Bundle ID `dev.quanru.localdesk`、现有配置目录 `dev.quanru.LanDesk` 相互独立。
安装、检测、卸载与更新由 `src/platform/macos.rs` 统一替换上游模板里的服务标识。

已安装旧开发版的机器可执行一次显式迁移；这不是运行时兼容分支：

```sh
python3 tools/native/migrate-macos-service.py --uid "$(id -u)"
# 先安装包含新服务标识的应用，再通过正常管理员认证执行：
sudo python3 tools/native/migrate-macos-service.py --uid "$(id -u)" --apply
```

脚本只接受指向 `/Applications/LanDesk.app` 且 Bundle ID 匹配的已知旧启动项。
先校验，再停旧服务、加载新服务，成功后移除旧 plist；加载失败则恢复原来已加载的服务。
不读取、移动或删除用户配置，也不更改其他应用的启动项。执行后核验两个新 job 以及应用首页。

迁移工具也支持新版已安装、旧版启动项仍存在的情况：先核验已有的新启动项，保留其配置，重新加载新服务后移除旧启动项；失败时恢复原先已加载的服务。默认不加 `--apply` 时只做校验。
