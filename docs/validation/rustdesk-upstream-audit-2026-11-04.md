# RustDesk 上游逐提交清单

核对版本：`55786aaa5709ac0a450aabcf06f9d1fee3119908`；LanDesk 对照 HEAD：`a3100992a98b399494c682c5528fd0b3353b9ece`；共同祖先：`5abf4e9724dc9a8c9b45dfe13e71af11616eb2c8`。

本清单覆盖共同祖先之后 RustDesk 的全部提交。分组是接入决策和后续队列，不能把‘暂缓’理解为已合入，也不能把 SHA 不同都算成功能缺失。
已有移植记录按提交标题或原 SHA 引用追溯，证据强度低于补丁等价；不代表完整安全审计或全端运行验收。

| 状态 | 提交数 |
| --- | ---: |
| 上游撤回／替代 | 6 |
| 不适用于现有流程 | 36 |
| 优先待移植 | 3 |
| 已有对应实现 | 3 |
| 已有移植记录 | 23 |
| 已有等价补丁 | 14 |
| 暂缓，未宣称同步 | 154 |
| 本次接入 | 32 |
| 本轮不接入 | 106 |
| 合计 | 377 |

## 优先队列

以下只列尚未接入的安全优先项；已接入项的平台验证边界见第四批验证记录。不能只凭本清单声称风险已消除。

- [`402ed07b0`](https://github.com/rustdesk/rustdesk/commit/402ed07b0ce6b815ed9818d4c9701599e8976e30)：fix: Harden Windows installer temp command scripts (#15634)
- [`f705902ec`](https://github.com/rustdesk/rustdesk/commit/f705902ec3dc2a4fc65d5d8a65cf99c026b8a135)：fix(windows): move installer scripts into protected temp directories (#16554)
- [`2b6fedfc8`](https://github.com/rustdesk/rustdesk/commit/2b6fedfc8e8e8ba35ec764dbcc81210cb5343333)：fix(windows): protect installer handoff and use native service control (#16562)

## 全部提交

| RustDesk 提交 | 标题 | 状态 | 依据／处理范围 |
| --- | --- | --- | --- |
| [`96e2a330b`](https://github.com/rustdesk/rustdesk/commit/96e2a330b86f1b2ffd31a70a9bb9565cace0d68f) | restrict switch sides to remote desktop sessions (#15610) | 已有移植记录 | 本地 `5d9d91472` 同题移植；后续分歧仍须分别核对 |
| [`61f094499`](https://github.com/rustdesk/rustdesk/commit/61f09449909241ad9b1ffa7d7c3ef47f4081a669) | Fix Adjust Window sizing across DPI (#15592) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`082a5a2a4`](https://github.com/rustdesk/rustdesk/commit/082a5a2a4ee80df65665b2271af460635edad884) | Revert "Fix Adjust Window sizing across DPI (#15592)" (#15620) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`5f015c9da`](https://github.com/rustdesk/rustdesk/commit/5f015c9da13cb227a414c6d295a5c81e5360eccb) | Translate Continue into Simplified Chinese (#15621) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c01300be2`](https://github.com/rustdesk/rustdesk/commit/c01300be201525afd73d6ac3fcf19a2d8b74a65d) | fix(ipc): never adopt an empty id from the main IPC (#15626) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`20ab5ab0a`](https://github.com/rustdesk/rustdesk/commit/20ab5ab0ad78a6ec6b92375f4cc483415ad75ff9) | fix(deploy): don't wipe local id when --deploy gets an empty --id (#15633) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`7696b0ee5`](https://github.com/rustdesk/rustdesk/commit/7696b0ee51a82133305cbcafec6fb1523f9df415) | fix(linux): forward forced display server to user server (#15627) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`5b4d6baf4`](https://github.com/rustdesk/rustdesk/commit/5b4d6baf47283068fbe03f2eacd2ec34d0c20c2c) | fix: wrap BackingScaleFactor in autoreleasepool to stop NSDictionary accumulation on macOS (#15623) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`1c2dd7189`](https://github.com/rustdesk/rustdesk/commit/1c2dd71891cd476a8952eab95d682cd33f3188c9) | Translate 'Continue' to 'Kontynuuj' in Polish (#15641) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`929e989f1`](https://github.com/rustdesk/rustdesk/commit/929e989f17ba92e1a8291c0616f705208b67e3ea) | feat(macos): silent auto-update with security hardening (#15550) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`beaa75429`](https://github.com/rustdesk/rustdesk/commit/beaa754299feff6d89a89e2e9f71d838788e333a) | fix stale primary display selection (#15460) | 已有移植记录 | 本地 `deb17df14` 同题移植；后续分歧仍须分别核对 |
| [`b4af82157`](https://github.com/rustdesk/rustdesk/commit/b4af82157bc5b44b62e66c1e7b50cc945bc42532) | fix: refresh wayland uinput range on compositor layout change (#15628) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`ad9dac100`](https://github.com/rustdesk/rustdesk/commit/ad9dac100102008ba1ae20067c0a4dac0fc6847c) | fix(keyboard): jis, macos, muhenkan henkan (#15669) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`cefff781d`](https://github.com/rustdesk/rustdesk/commit/cefff781d4994a306452dcd584336ee0896e2e15) | feat(recording): add visibility and service storage options (#15662) | 已有移植记录 | 本地 `376125ee3` 同题移植；后续分歧仍须分别核对 |
| [`57456f0b5`](https://github.com/rustdesk/rustdesk/commit/57456f0b52a50888e60b218f709af06f2cb1b205) | feat(terminal): add Ctrl and Alt toggles to mobile terminal keyboard (#15532) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`b1fad7bbe`](https://github.com/rustdesk/rustdesk/commit/b1fad7bbed5f736e34c7a718ecc4f54c3c33f0aa) | fix: validate RGBA clipboard dimensions (#15672) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`5882346ca`](https://github.com/rustdesk/rustdesk/commit/5882346caa9211c16180be6540b72d671fd71215) | fix: validate remote audio channel count (#15673) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`eefd22b20`](https://github.com/rustdesk/rustdesk/commit/eefd22b2057ba057305b10a6b5bf93c79b686eb9) | fix(macos): prevent remote keyboard focus leaks (#15629) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`d6ea17006`](https://github.com/rustdesk/rustdesk/commit/d6ea170061576546d64777ddb0f4ce93efa051e3) | Id whitelist (#15586) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`dabdbf73b`](https://github.com/rustdesk/rustdesk/commit/dabdbf73bb80f1718879fe879619d83c72103041) | improve id wildcast | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`4dd8e2039`](https://github.com/rustdesk/rustdesk/commit/4dd8e203922f2bc3898ddd06a098617381d36674) | improve id whitelist login failures | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`d412d1987`](https://github.com/rustdesk/rustdesk/commit/d412d198720aa56f6cfed2dfad262e8fb1322fb7) | aligned_u8_vec | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`85a5fefab`](https://github.com/rustdesk/rustdesk/commit/85a5fefab8b3a29135c488e19a79f43d027576ad) | fix(windows): prevent ghost and duplicate tray icons (#15689) (#15690) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`a6708f40e`](https://github.com/rustdesk/rustdesk/commit/a6708f40e710aba635af96d03d9cc4bd29330580) | fix https://github.com/rustdesk/rustdesk/issues/15703 | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`12f2de595`](https://github.com/rustdesk/rustdesk/commit/12f2de5959fa1fcd36d5a5b0c2fa91657411cc7a) | chore(flutter): point window_manager at the post-revert main (#15709) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`72c052cb9`](https://github.com/rustdesk/rustdesk/commit/72c052cb9aa756895e1b59d2a7cc69a76d036a37) | docs: fix double space in CODE_OF_CONDUCT.md (#15714) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`8545b5ed9`](https://github.com/rustdesk/rustdesk/commit/8545b5ed9829b06e25f884adda3b5578694e2903) | docs: fix 'gressful' misspelling to 'graceful' in libs/clipboard/README.md (#15713) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3442648af`](https://github.com/rustdesk/rustdesk/commit/3442648afe30bcdd24145b0de2e18f9e762f2c96) | docs: fix 'lowlevel' spelling to 'low-level' in libs/clipboard/README.md (#15712) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`9aeb54cf3`](https://github.com/rustdesk/rustdesk/commit/9aeb54cf33a5ac77bf5c0adb1d4f8309ba78abe5) | Fix flutter white window forceredraw (#15717) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`e63df7471`](https://github.com/rustdesk/rustdesk/commit/e63df747156c9db2cb74ae342e119a2a418371ea) | fix(linux): make quit_cm actually quit the connection manager (#15718) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`c6c53f094`](https://github.com/rustdesk/rustdesk/commit/c6c53f094a2705de33a95e3196eb20cbb2f6deb2) | chore(flutter): bump desktop_multi_window to fix the Windows /WX build | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`5aeb4cf94`](https://github.com/rustdesk/rustdesk/commit/5aeb4cf945ee6f08afd9f4be672873c67dfbcbf8) | add zstd to reqwest | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`006b9737e`](https://github.com/rustdesk/rustdesk/commit/006b9737e4224b54f30375b5d7eb2fa6ecc618c4) | fix(linux): load librustdesk.so relative to the executable (#15719) | 已有移植记录 | 本地 `8e0d1bc48` 同题移植；后续分歧仍须分别核对 |
| [`e0254d997`](https://github.com/rustdesk/rustdesk/commit/e0254d997e89377070291350398bb72db1e03f17) | fix ci | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`807e05ea9`](https://github.com/rustdesk/rustdesk/commit/807e05ea9a7e298ed2deb438195faaafce19cdd2) | refact(oidc): login with api domain (#15710) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`b19f1ef76`](https://github.com/rustdesk/rustdesk/commit/b19f1ef76f3cbfadc1a95b9d669c272ba7f02ef5) | Add SBOM (Software Bill of Materials) for the EU Cyber Resilience Act (EU CRA) (#15732) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`6c69faaa1`](https://github.com/rustdesk/rustdesk/commit/6c69faaa1c4fedd22dedd6fd03948ab6fb60665e) | Update de.rs (#15733) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`a5018a022`](https://github.com/rustdesk/rustdesk/commit/a5018a022b78ca410a1569c1dfdc82e755f3a65b) | chore(ios): remove unused GoogleService-Info.plist (#15752) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`ffe20bb29`](https://github.com/rustdesk/rustdesk/commit/ffe20bb297a1d7966b769a9907d40e34888a0426) | Login options error feedback (#15727) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`2f8822ec7`](https://github.com/rustdesk/rustdesk/commit/2f8822ec7a93e15c21df58f472bcac02e7f86dbe) | Update nl.rs (#15754) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`d752823b8`](https://github.com/rustdesk/rustdesk/commit/d752823b8c2e0f5153df18de604911234eb39fc8) | swtich_code for hbbs (#15615) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`e6dd925ab`](https://github.com/rustdesk/rustdesk/commit/e6dd925ab0fcb7b3e4061927cf2b5faa317fe99f) | fix(android): close outgoing sessions when the task is swiped away (#15753) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`a84bad463`](https://github.com/rustdesk/rustdesk/commit/a84bad4639689e37d4278544aeeb0d89745dd950) | refact(oidc): manually open the browser (#15706) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`4389687d9`](https://github.com/rustdesk/rustdesk/commit/4389687d9d08b8957675b923b8a1564fc57e32e4) | fix(wayland): subscribe to portal Response before making the request (#15726) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`6f1eb164d`](https://github.com/rustdesk/rustdesk/commit/6f1eb164d616e0e2bfbcf8c6b7c8083b09d7ed06) | fix(clipboard): validate files (#15693) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`3cf32e706`](https://github.com/rustdesk/rustdesk/commit/3cf32e70666006e0273938bf64c6e6e67d3bb82f) | fix(wayland): scale portal pointer coordinates on niri (#15683) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`402ed07b0`](https://github.com/rustdesk/rustdesk/commit/402ed07b0ce6b815ed9818d4c9701599e8976e30) | fix: Harden Windows installer temp command scripts (#15634) | 优先待移植 | Windows 安装器脚本／提权交接／服务控制加固；需保留 LanDesk 品牌并验证标准用户、管理员和特殊字符路径，Mac 检查不能替代 |
| [`ef3a57580`](https://github.com/rustdesk/rustdesk/commit/ef3a57580faabe033edcdfbb915f8953c431034e) | Update Dutch translation (#15767) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`7eb915011`](https://github.com/rustdesk/rustdesk/commit/7eb915011626f99fa48b35a6fd45aab6f9e2fa82) | Audit retry nonce (#15759) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`cc85685b9`](https://github.com/rustdesk/rustdesk/commit/cc85685b96af6f51df2ac7a1d36a996dddc90bb2) | fix(linux): stop losing every inhibitor when the ScreenSaver name is absent (#15772) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`f5ab01f8b`](https://github.com/rustdesk/rustdesk/commit/f5ab01f8bd779159765bb8fa5ed0b1d82fa9e6bf) | fix(clipboard): win, populate file formats (#15692) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`ddad47925`](https://github.com/rustdesk/rustdesk/commit/ddad47925c6f1e429e5dfd930cacad0be1f2721b) | feat(linux): DRM/KMS direct capture for Wayland — no portal consent required (#15420) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`9a81c8a13`](https://github.com/rustdesk/rustdesk/commit/9a81c8a1383dde703e8b667eef4fc924d52e514e) | Drm deb in release workflow (#15776) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`429c8c671`](https://github.com/rustdesk/rustdesk/commit/429c8c67111408bbc04e96a8a38252210fb1b1f2) | Translate sign-in message to Portuguese (#15770) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`6fd96dda6`](https://github.com/rustdesk/rustdesk/commit/6fd96dda6ec73bd03663c1c33493bceceb0e707d) | Update Greek translations for various terms (#15782) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`4234b9902`](https://github.com/rustdesk/rustdesk/commit/4234b99029bf32c23098b4eaeec8efc135c8e80a) | WebClient:  3.44 webcodecs offline (#15722) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`d057fe14b`](https://github.com/rustdesk/rustdesk/commit/d057fe14b2fb24d7a4cd6d64fb9f1c6d72dbea3f) | docs: fix singular contribution in docs/CONTRIBUTING.md (#15789) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`11190fa54`](https://github.com/rustdesk/rustdesk/commit/11190fa54e45fd244ad46b46052f92be6a01d3c5) | docs: fix comma splice gui tutorial in README.md (#15787) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`291507664`](https://github.com/rustdesk/rustdesk/commit/291507664278f0df273c31f58b9318ff44b28a18) | fix(linux): bound the xrandr call in the wayland primary-display lookup (#15802) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`7c23fd307`](https://github.com/rustdesk/rustdesk/commit/7c23fd307349c2d436dbcadc9cff9d4099187a42) | Revert "fix(linux): bound the xrandr call in the wayland primary-display look…" (#15806) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`594e63805`](https://github.com/rustdesk/rustdesk/commit/594e63805c2fa2e6b214c07dd7869dba52f4d627) | harden login request retry | 已有移植记录 | 本地 `64efc2ec7` 同题移植；后续分歧仍须分别核对 |
| [`d407db9fa`](https://github.com/rustdesk/rustdesk/commit/d407db9faed8d7f45184fd8862b5dd728a2ae6fb) | fix(client): allow switch-sides back-connection in incoming-only mode (#15780) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`947cb3f17`](https://github.com/rustdesk/rustdesk/commit/947cb3f17b673b55dfcbe95b318749f8b44a7f7a) | propagates the hash-handler continuation result through both connection loops, allowing incoming-only rejection to terminate the connection while preserving existing login flows. | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`ff07ff7f1`](https://github.com/rustdesk/rustdesk/commit/ff07ff7f13a7c4a350519243b803759207978817) | fix(terminal): send SGR mouse wheel reports with the button codes app… (#15817) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`23256e6ac`](https://github.com/rustdesk/rustdesk/commit/23256e6ac1687ba63c38a3d55a64e1b04c8c637a) | fix(i18n): complete Traditional Chinese sign-in strings (#15829) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`1d09760ef`](https://github.com/rustdesk/rustdesk/commit/1d09760ef7c9275555ac512d66fee5af549c5d06) | fix(terminal): keep selection aligned after clearing scrollback (#15831) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`63822048d`](https://github.com/rustdesk/rustdesk/commit/63822048df9c86ecb3b6bd9000a130a7a0919f2f) | fix: upgrade fuser to 0.16.0 (GHSA-cvmj-47v9-35m9) (#15834) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`10bcf976f`](https://github.com/rustdesk/rustdesk/commit/10bcf976f7cf3ebe0a4e196dbd2b1c89e85dcac7) | Revert "fix: upgrade fuser to 0.16.0 (GHSA-cvmj-47v9-35m9) (#15834)" (#15841) | 上游撤回／替代 | 原修改与回退不成对重放；采用当前分支的后续实现 |
| [`dfca2c1b8`](https://github.com/rustdesk/rustdesk/commit/dfca2c1b8f401b24c231cca75b155ed6aa3b518c) | update agents.md | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c4fd7d692`](https://github.com/rustdesk/rustdesk/commit/c4fd7d692dc657e3bc87e1f75f3308e9cd426987) | refact: fuser 0.16.0, cargo 1.75.0 (#15844) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`d829d1410`](https://github.com/rustdesk/rustdesk/commit/d829d1410a49123fcf4209496a4788f4cc02eec5) | fix(linux): serve the Wayland login screen the DRM backend was built for (#15792) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`d1da05c4d`](https://github.com/rustdesk/rustdesk/commit/d1da05c4dbf3e4f3f87c89da3ddfb2614164a3b3) | refact: remove feature plugin-framework (#15854) | 已有对应实现 | LanDesk 已删除插件运行时和入口，保留自己的残留门禁 |
| [`7aa98d43c`](https://github.com/rustdesk/rustdesk/commit/7aa98d43cf1962a7a29ec16ffef42974377ef11e) | Refact/plugin removal leftovers (#15864) | 已有对应实现 | LanDesk 已删除插件运行时和入口，保留自己的残留门禁 |
| [`8d52d48b2`](https://github.com/rustdesk/rustdesk/commit/8d52d48b2431f25d2cacdf5373d9653002215486) | docs: fix dead code of conduct links in ID/IT contributing guides (#15868) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3871c4785`](https://github.com/rustdesk/rustdesk/commit/3871c47855eec2d3dab1f16dc7f2dbcecfbdcf1d) | docs: remove stale flutter/web/js entry and fix dead localized build links (#15869) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`edd0e5fbd`](https://github.com/rustdesk/rustdesk/commit/edd0e5fbd44729e6371ead9bcfabdd541317b8af) | fix(CI): rust 1.75, linux sciter (#15874) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`5a78be03e`](https://github.com/rustdesk/rustdesk/commit/5a78be03e3c2edb676b7e5b0bcab6a5c9a47d26d) | feat(rdp): title the mstsc window after the peer instead of "localhost" (#15781) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`8ffe3117a`](https://github.com/rustdesk/rustdesk/commit/8ffe3117a53716f1df431879b69132c71f969cc3) | feat(flutter): add mobile canvas lock (#15877) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`14a4b197a`](https://github.com/rustdesk/rustdesk/commit/14a4b197adc8b80fc954ad11fde50d443305a176) | translations | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`6a27910f3`](https://github.com/rustdesk/rustdesk/commit/6a27910f34aa2e0280e77dac1170573947bea6ff) | fix(wayland): back off the polling display lookups after a failure (drm) (#15865) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`9b1b810d3`](https://github.com/rustdesk/rustdesk/commit/9b1b810d3a052e1897e10a701cb3e938dd69465a) | Delete .github/dependabot.yml (#15888) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0c00d576d`](https://github.com/rustdesk/rustdesk/commit/0c00d576dd104cb83b10f492be2f0ec790c0183a) | improve comment rules | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`b0008edcb`](https://github.com/rustdesk/rustdesk/commit/b0008edcb57712eaf95dbcc3ee610ab8727a9919) | refact: remove linux headless (#15866) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`198467878`](https://github.com/rustdesk/rustdesk/commit/19846787855aaf5031d34e54e0495f20b26083aa) | Hide printer tab when settings disabled (#15901) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`630b53110`](https://github.com/rustdesk/rustdesk/commit/630b531108f48363dac096de41729a454978ab66) | fix(flutter): initialize the cursor hotspot y from its own origin (#15898) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`567967050`](https://github.com/rustdesk/rustdesk/commit/56796705060a9f3297b542988928e4f15f125271) | fix(flutter): make Adjust Window reliable across desktop platforms (#15853) | 已有移植记录 | 本地 `87f9e7901` 同题移植；后续分歧仍须分别核对 |
| [`0a4b431ea`](https://github.com/rustdesk/rustdesk/commit/0a4b431ea224757cb46796bad3b065f3a97013eb) | fix: correct terminal mouse selection and scroll coordinates (#15915) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`f1a06f676`](https://github.com/rustdesk/rustdesk/commit/f1a06f67653029baa2a3959763ed52d7959c2bf6) | review rules | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`798b73beb`](https://github.com/rustdesk/rustdesk/commit/798b73beb120d333902e4ff87a5e7587f343320c) | Update common.rs (#15924) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`c45f7d2dd`](https://github.com/rustdesk/rustdesk/commit/c45f7d2dd222b0cb323ddfbd65d19dd7b8eb10b2) | refactor is_public | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`c78bdefc4`](https://github.com/rustdesk/rustdesk/commit/c78bdefc44838301c7588be582a9a10e18a6cdf8) | fix: dialog, trackpad speed, buttons (close -> ok, cancel) (#15918) | 已有移植记录 | 本地 `809a2f988` 同题移植；后续分歧仍须分别核对 |
| [`61ddade04`](https://github.com/rustdesk/rustdesk/commit/61ddade049dd048415e8fca9ba2c81cba13e5139) | fix(windows): restore keyboard focus when the cursor re-enters the remote image (#15880) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`92eb13717`](https://github.com/rustdesk/rustdesk/commit/92eb13717865a3b6ed03ff3f3824a53ee443e111) | feat(terminal): use platform-native copy and paste shortcuts (#15931) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`6eaac17ac`](https://github.com/rustdesk/rustdesk/commit/6eaac17ac5be69a81892300bc7b1535408f07fa1) | typo | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`cbf944028`](https://github.com/rustdesk/rustdesk/commit/cbf94402816bb0a20e7b1fa21b3ab7f524d65105) | Prefer active X11 session display (#15933) | 已有移植记录 | 本地 `4ea1c0464` 同题移植；后续分歧仍须分别核对 |
| [`e266380ee`](https://github.com/rustdesk/rustdesk/commit/e266380ee91e2b8cc9d662b3a3ca1fd6f143d48b) | fix(appimage): keep the XDG default data dirs on XDG_DATA_DIRS (#15938) | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`d5a7f6799`](https://github.com/rustdesk/rustdesk/commit/d5a7f67999ed5936f4553a64c0b3f638c9ff75b9) | fix appimage pixbuf crash | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`a7deef02a`](https://github.com/rustdesk/rustdesk/commit/a7deef02a20cdfeed7d90fe3bcccf8ada204e888) | fix(msi): keep only native ProductCode uninstall entry (#15891) | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`7423dced3`](https://github.com/rustdesk/rustdesk/commit/7423dced37845c48093b6f71bd82e4a16cc8c79d) | Update reference from AGENTS.md to @AGENTS.md | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`a3bab27a2`](https://github.com/rustdesk/rustdesk/commit/a3bab27a2a7875ae910293f474416ce8d9151f40) | fix: Show My Cursor freezes in View Only mode when remote user mo... (#15936) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`f07b6e233`](https://github.com/rustdesk/rustdesk/commit/f07b6e2338b03ef24e88d5063747da616c2c9f1c) | Correct Danish spelling, language and translation (#15943) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`7cc82c157`](https://github.com/rustdesk/rustdesk/commit/7cc82c1575f77460168ce467147770b220294c10) | Add Urdu language support for UI strings (#15961) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`893dc2779`](https://github.com/rustdesk/rustdesk/commit/893dc277983a66f815e2937073ac9ef1396885bf) | docs(readme): fix broken Screenshots section anchor link (#15964) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0d917c6fa`](https://github.com/rustdesk/rustdesk/commit/0d917c6fa15871b77791735851a483f5fc011418) | fix: remove dup translations (#15967) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`cec408523`](https://github.com/rustdesk/rustdesk/commit/cec4085238ee723b75095e94014e8595f374688b) | Bump aom to v3.14.1 (#15883) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`3f207e91f`](https://github.com/rustdesk/rustdesk/commit/3f207e91f6061b637f704f94074ee487b030625f) | fix(linux): a session logout should hand the peer to the login screen (#15905) | 已有移植记录 | 本地 `cc8639ce6` 同题移植；后续分歧仍须分别核对 |
| [`7c6e661fc`](https://github.com/rustdesk/rustdesk/commit/7c6e661fcc958ad6532647a9a6c0c95e224383c8) | fix(linux): Set AppIndicator ID for tray-icon (#15981) | 已有移植记录 | 本地 `f0da8cb36` 同题移植；后续分歧仍须分别核对 |
| [`fd471fcf0`](https://github.com/rustdesk/rustdesk/commit/fd471fcf028eaef38a447f03a5a482251208117b) | fix: show speed in desktop file transfer status (#15980) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`7220f0041`](https://github.com/rustdesk/rustdesk/commit/7220f004102625d59905964f9d15db670cf4653c) | fix(linux): a Wayland session without XAUTHORITY is not incomplete (#15978) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`e9b81e347`](https://github.com/rustdesk/rustdesk/commit/e9b81e347599b61ed7436c7d521af3a935582ffc) | typo | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`0b08a83d4`](https://github.com/rustdesk/rustdesk/commit/0b08a83d4b6d4d1ebeea98a0b6e94f46bb3ff33e) | fix(file-transfer): improve large directory loading (#15830) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`1fe451c2e`](https://github.com/rustdesk/rustdesk/commit/1fe451c2e819e95cb09a00b36b3efdc132df3cb7) | chore(flutter): bump desktop_multi_window for show recovery (#15959) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`03a7fc599`](https://github.com/rustdesk/rustdesk/commit/03a7fc5992069cc5bc9f7c36b872483dddf4f472) | fix(flutter): align terminal shortcuts with platform conventions (#15970) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`d4b06a6c5`](https://github.com/rustdesk/rustdesk/commit/d4b06a6c5ca36596970d7c8f087687be3c3772f7) | fix: android: replace all-files access with scoped storage (#15602) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`169f74f8d`](https://github.com/rustdesk/rustdesk/commit/169f74f8d90260b2083f3587ca0eba34ef30af4d) | fix(ci): check out submodules in update-webpki-roots | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`66ab0b87f`](https://github.com/rustdesk/rustdesk/commit/66ab0b87f696182b9fce5403fe48bdcab00d3ba1) | Linux drop shell from service loop (#15979) | 已有移植记录 | 本地 `1a2db5fea` 同题移植；后续分歧仍须分别核对 |
| [`2c84c8fb1`](https://github.com/rustdesk/rustdesk/commit/2c84c8fb1333bfbc3c4850d460a07ab75711ecf0) | change to 3.44.9 flutter for arm | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`1ec1b9e7e`](https://github.com/rustdesk/rustdesk/commit/1ec1b9e7e3808b24bfc923ee1e6800ab9694e9a5) | fix: android: target API 36 (#15603) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`28cf1836e`](https://github.com/rustdesk/rustdesk/commit/28cf1836e62442e9bccfa3033c9d5e6cf67de1e8) | bump to 1.5.0 | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`f28ac38cc`](https://github.com/rustdesk/rustdesk/commit/f28ac38ccfa662fd06639a062e0d06249860b142) | feat: optionally sync clipboard between connected sessions (#15934) | 已有移植记录 | 本地 `8906fb222` 同题移植；后续分歧仍须分别核对 |
| [`c312385ff`](https://github.com/rustdesk/rustdesk/commit/c312385ffddd89ce6df4138db49bded31dcce924) | Update tw.rs (#16031) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`957dfe8c9`](https://github.com/rustdesk/rustdesk/commit/957dfe8c96203fa48628c4eea25a6d3685ca9666) | feat: add admin and control role API scripts (#16035) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`dfb5804dd`](https://github.com/rustdesk/rustdesk/commit/dfb5804dd0135aef1171c7acbde5ef9c48f818a1) | Update nl.rs (#16036) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0fd1a0eec`](https://github.com/rustdesk/rustdesk/commit/0fd1a0eecba9ff296d8e352fddef6d41fe9ff078) | Custom client no rebuild (#15774) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`6dbd81045`](https://github.com/rustdesk/rustdesk/commit/6dbd81045446a4fb4ef5eda21c58b0856d842fdb) | Translate export-related strings to Portuguese (#16038) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`e4539fc30`](https://github.com/rustdesk/rustdesk/commit/e4539fc3043bc6dfb2b52656e88ee3b30b3b14b1) | Update cn.rs (#16041) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`23a147b0d`](https://github.com/rustdesk/rustdesk/commit/23a147b0dc9e92705c54faf123d0d71fe27e2e91) | Filter detached DXGI outputs for Win+P single-display modes (#15814) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`3f93005be`](https://github.com/rustdesk/rustdesk/commit/3f93005be276f4a7c0cf36a374753a003d17a1c8) | fix(drm): deliver a rotated output upright (#15886) (#15889) | 已有移植记录 | 本地 `afce44aa1` 同题移植；后续分歧仍须分别核对 |
| [`82aa28f12`](https://github.com/rustdesk/rustdesk/commit/82aa28f129b187e05191d557300eecf760bd12a1) | fix(ci): install CMake 4.3 for ARM64 vcpkg builds (#16044) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`a59ad333f`](https://github.com/rustdesk/rustdesk/commit/a59ad333fcc9619c323a02f625e10ca395d0c580) | fix: delimit FFmpeg pkg-config option (#16055) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`ba6de7990`](https://github.com/rustdesk/rustdesk/commit/ba6de7990f6850423fe8adeb717de85a72f902a5) | fix(ci): ubuntu-22.04-arm, oom (#16056) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`b6ff62c74`](https://github.com/rustdesk/rustdesk/commit/b6ff62c74b3a75d32b5c62864c0be9c054b17f79) | l10n: fill remaining Swedish entries (#16050) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`d5c6d0f6b`](https://github.com/rustdesk/rustdesk/commit/d5c6d0f6b7dbf914c396ab62a430ecec838f8b00) | fix(custom client): msi update, preserve exe name (#16057) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`50c4e435d`](https://github.com/rustdesk/rustdesk/commit/50c4e435de8991e75777b7fed9dd5aface28285a) | connection: apply the non-video send timeout once the type is known (#16063) | 已有移植记录 | 本地 `2460c8d3c` 同题移植；后续分歧仍须分别核对 |
| [`d453a1960`](https://github.com/rustdesk/rustdesk/commit/d453a19601b0c48bc0afa495a31756ecee68a279) | AGENTS.md: require a regression-surface check before a change is done (#16068) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`978c901f4`](https://github.com/rustdesk/rustdesk/commit/978c901f49565abb188a0526929c429869b023cd) | port forward: a login's target and challenge travel with its own accept (#16069) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`9a1c8da14`](https://github.com/rustdesk/rustdesk/commit/9a1c8da14382e0a5205eabd397fbaf21be320566) | Agents regression surface (#16070) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c1a587cfa`](https://github.com/rustdesk/rustdesk/commit/c1a587cfa487e04d16baa172d9b108691e7d2d39) | connection page: the Connect menu offers TCP tunneling, as the peer card does (#16075) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`618bf37de`](https://github.com/rustdesk/rustdesk/commit/618bf37debba4ec812e415742d0695a572b2423e) | feat(terminal): add opt-in OSC 52 clipboard writes (#16072) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`3fc11c0f8`](https://github.com/rustdesk/rustdesk/commit/3fc11c0f814379bc3ed6a067d20326ad42404eca) | port forward shared conn (#16062) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`ae6af2de4`](https://github.com/rustdesk/rustdesk/commit/ae6af2de43f11a37bd6a5b25a7dd6aad1ada8c63) | Webrtc (#15684) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`942810d43`](https://github.com/rustdesk/rustdesk/commit/942810d432bec313c8de7d1ed5a09e12e2314156) | bump hbb_common: main after the webrtc merge | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`254d98129`](https://github.com/rustdesk/rustdesk/commit/254d98129d7eeb00d3fdc2f034b1ad074d0b0673) | ci: use thin LTO for the armv7 sciter build | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`dc04b911a`](https://github.com/rustdesk/rustdesk/commit/dc04b911a1f94919d4dbaedc172fab83b8cba1a4) | Update it.rs (#16085) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`692113c87`](https://github.com/rustdesk/rustdesk/commit/692113c87e476c2e8a82a7cdb9aa98354abc11fc) | bump webrtc: probe on T3-rtx, settle the rest by the SACK, RTO from the latest send | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`92d787b88`](https://github.com/rustdesk/rustdesk/commit/92d787b885af458d1828de6c74cc3c3d523881d2) | fix: clipboard, preserve uncompressed special format data (#16100) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`e8eead571`](https://github.com/rustdesk/rustdesk/commit/e8eead571516dac0669e64b186208979d79282eb) | Add Galician language support for UI strings (#16101) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`b50fde691`](https://github.com/rustdesk/rustdesk/commit/b50fde6910f6f5910ea96c0cade0736e7129dee3) | add the base crate and repoint the moved modules at it (#16107) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`59fdda383`](https://github.com/rustdesk/rustdesk/commit/59fdda38350f18c910a0c2aa78ea96d298afdfd2) | file transfer: a send_confirm past the last file no longer panics | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`e5d473407`](https://github.com/rustdesk/rustdesk/commit/e5d473407e1daeb312eb8b3c70e955645fd31252) | fix https://github.com/rustdesk/rustdesk/issues/16086 | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0f0205d33`](https://github.com/rustdesk/rustdesk/commit/0f0205d3367add427b01925089b0d3808e4a2623) | feat: add Azerbaijani translation (#16103) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`22b1ed169`](https://github.com/rustdesk/rustdesk/commit/22b1ed169aa473b320e338c546f1f7b9a511f23f) | fix(audio): update CPAL for WASAPI thread priority (#16110) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`691830fe8`](https://github.com/rustdesk/rustdesk/commit/691830fe89ed7ef28332ff926844eb691d7906c5) | bump webrtc: revert the T3-rtx probe recovery (#16121) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`5228f9198`](https://github.com/rustdesk/rustdesk/commit/5228f919829e5a7fe3a9febd6f354df21dcc9336) | fix(screenshot): keep cached image when saving fails (#16120) | 已有等价补丁 | git cherry / stable patch ID 匹配；不是缺失提交 |
| [`68359a2dd`](https://github.com/rustdesk/rustdesk/commit/68359a2dd2c44999c857d360e3c1bb5dbac4fccb) | fix(macOS): preserve release entitlements when signing (#16125) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`01dbb7649`](https://github.com/rustdesk/rustdesk/commit/01dbb764996f9f88d2cb7bcc06e26f86ce8396db) | server: do not lock the screen for a connection a reconnect replaced (#16124) | 已有移植记录 | 本地提交说明引用原始 SHA；不据此宣称逐行或运行时完全相同 |
| [`080211ff3`](https://github.com/rustdesk/rustdesk/commit/080211ff36b24ed146818aa9da6a5c7ca2822ffc) | improve qos (#16082) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`f164c9a9d`](https://github.com/rustdesk/rustdesk/commit/f164c9a9dfecc68a8fcc5176e974fd5a52bceeb4) | Dead peer recovery (#16117) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`bac8323e5`](https://github.com/rustdesk/rustdesk/commit/bac8323e5d27e6aa4bb9b804bc6429b1be39bd3c) | Wayland portal staged errors (#16118) | 已有移植记录 | 本地 `eb3627089` 同题移植；后续分歧仍须分别核对 |
| [`65edf214b`](https://github.com/rustdesk/rustdesk/commit/65edf214b9801c879a1cd7b3e18a6b3c0ea7244c) | fix(macos): recover system-stopped audio capture streams (#16123) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`aa232a9df`](https://github.com/rustdesk/rustdesk/commit/aa232a9dfa2c90f79a8040772d994999a683e799) | chore(flutter): pin our own git plugins instead of tracking their HEAD | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`97190f715`](https://github.com/rustdesk/rustdesk/commit/97190f715ba50d50204ba987164f4ae597fdb932) | fastlane: add es-ES Android metadata (#16136) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3ffee7c1f`](https://github.com/rustdesk/rustdesk/commit/3ffee7c1ff64dd78a9eb9e562bb14f8db4cac054) | fastlane: add pt-BR Android metadata (#16135) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`435fe24a8`](https://github.com/rustdesk/rustdesk/commit/435fe24a816819ec2d093be02b491bdacc2c7ca9) | Fix formatting and punctuation in full_description.txt (#16138) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`14a5ed45d`](https://github.com/rustdesk/rustdesk/commit/14a5ed45d95d7b31840fabc8a343b1ac221b2c65) | Revise full description for Android app pt-BR (#16140) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`5cfe136fb`](https://github.com/rustdesk/rustdesk/commit/5cfe136fb082042524469a1805c745ee7ec0aba0) | fix mac sign | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`978e2e28b`](https://github.com/rustdesk/rustdesk/commit/978e2e28b9d3e12b0d3589604bb6f04f13afdeda) | fix(audio): restart capture when the device is unavailable (#16142) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`c4221469d`](https://github.com/rustdesk/rustdesk/commit/c4221469d88c28545a33e5e81c4112ff375789f7) | Fix/audio stream continuity (#16095) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`91c9fccbb`](https://github.com/rustdesk/rustdesk/commit/91c9fccbb0f7bfe5f11644d5fbdec9b23fa10540) | chore(deps): security bumps in Cargo.lock (RUSTSEC-2026 fixes) (#16143) | 本次接入 | 第二批 20 项；仅 bytes/crossbeam-epoch，未恢复已移除的 quinn |
| [`67e0a1f58`](https://github.com/rustdesk/rustdesk/commit/67e0a1f5827160f8eacb311d283a7fa7083b9132) | Update it.rs (#16157) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0843447c4`](https://github.com/rustdesk/rustdesk/commit/0843447c41accc2e9c4826def0845ce9438f276b) | Fix Portuguese translations for error messages (#16159) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`d5311574b`](https://github.com/rustdesk/rustdesk/commit/d5311574be4a6653f0a0080ac0a3441408890bd3) | fix(flutter): show the quality monitor's Transport row on the web only | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`e82dd1235`](https://github.com/rustdesk/rustdesk/commit/e82dd12350479b848630d1e500c2f6870609a884) | Lower QoS sample logging to trace (#16161) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`e54f21e10`](https://github.com/rustdesk/rustdesk/commit/e54f21e10c5923ebae84b87d92ebfb59dfe17be4) | Fix/ci (#16168) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3c7c13d79`](https://github.com/rustdesk/rustdesk/commit/3c7c13d79d177c278a2f9749b3bcf7e75b0c978f) | timeout of webrtc fallback to delay | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`bf1ebe5be`](https://github.com/rustdesk/rustdesk/commit/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa) | Ci/native arm64 msbuild (#16170) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`70d45051f`](https://github.com/rustdesk/rustdesk/commit/70d45051f6eb1b3d2d930315810349c475c3b47b) | update base image in Dockerfile (#16176) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`8b716c704`](https://github.com/rustdesk/rustdesk/commit/8b716c7046f57c00c55f69167a4277193dd84d78) | flutter: fix End connetion typo (#16202) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`e4b9594c5`](https://github.com/rustdesk/rustdesk/commit/e4b9594c5ee688f63a607f1742816def0b634e46) | fix(android): exclude android from fixed 64 audio buffer size (#16198) | 本次接入 | 第二批 20 项 |
| [`5d7e20103`](https://github.com/rustdesk/rustdesk/commit/5d7e20103a7c3f677d9673a7bb6b154a582c9a70) | Translate terminal clipboard tips to Portuguese (#16183) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`9f60bb6fc`](https://github.com/rustdesk/rustdesk/commit/9f60bb6fc571c364c134b7d6c325515b7899000e) | Update it.rs (#16171) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`34c340be4`](https://github.com/rustdesk/rustdesk/commit/34c340be4e3832346c22dc8f7b9790428ad5c652) | Upgrade FFmpeg to 7.1.1 to fix HEVC WPP deadlocks (#16169) | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`cdcb4d4b4`](https://github.com/rustdesk/rustdesk/commit/cdcb4d4b4c0ce6040ed39a97de1eddc31bb50131) | Fix/android voice call (#16180) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`9b5f34283`](https://github.com/rustdesk/rustdesk/commit/9b5f3428397c0812d07a6af112db43582016a4bf) | fix(audio): throttled debug logs (#16172) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`4515cd646`](https://github.com/rustdesk/rustdesk/commit/4515cd646395030cbc4513ebfc1139ff645e7c00) | Update Korean (#16197) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`d0ee56d34`](https://github.com/rustdesk/rustdesk/commit/d0ee56d349a790dc52f26cdba70781a6e95fb28e) | fastlane: add it-IT Android metadata (#16162) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`29772f659`](https://github.com/rustdesk/rustdesk/commit/29772f65954056ce4484e7ecf70d46fa66a4f9af) | fix https://github.com/rustdesk/rustdesk/issues/16208 | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`82b6fc2f3`](https://github.com/rustdesk/rustdesk/commit/82b6fc2f3b1966d1cd6c6202136ae6ff1a2999c9) | https://github.com/rustdesk/rustdesk/pull/16199/ | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`b48fe17b5`](https://github.com/rustdesk/rustdesk/commit/b48fe17b52c0f87a644e15096a2c7d701d6a36ae) | Update Italian language (#16211) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`bd028ad35`](https://github.com/rustdesk/rustdesk/commit/bd028ad350d7f7f0540f41ee962c429d5237c5bd) | Update Korean (#16212) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`39d4f1854`](https://github.com/rustdesk/rustdesk/commit/39d4f1854b6fc0ebf6df2477598b970e6d1f73bf) | chore(qos): remove verbose diagnostics while retaining trace logs (#16214) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`a437eb9bc`](https://github.com/rustdesk/rustdesk/commit/a437eb9bc64408c1649df2b75b09187942273e9b) | fix(windows): recognize Hyper-V Enhanced Sessions by protocol (#16223) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`be757de46`](https://github.com/rustdesk/rustdesk/commit/be757de462127446ad01e2e90cdac1f1619341cb) | Update ru.rs (#16217) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`851d2df88`](https://github.com/rustdesk/rustdesk/commit/851d2df88cc8ef7a8368f74e8b2e7254861ee00a) | fix(audio): three 100% CPU busy loops on the _pa path (#16229) | 本次接入 | 第二批 20 项 |
| [`20e25e743`](https://github.com/rustdesk/rustdesk/commit/20e25e743d32c22a9ba3ff133dd5930d83c87d1d) | Fix Portuguese translations in ptbr.rs (#16234) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`28269af9c`](https://github.com/rustdesk/rustdesk/commit/28269af9c792a65a61f3c790cf81291294af66ff) | fix(audio): preserve compatible playback and recover failed Windows outputs (#16150) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`8154c026a`](https://github.com/rustdesk/rustdesk/commit/8154c026a4ce1ce1df63f3e4b835d3791be3b4e7) | fix(android): default to entire screen for capture (#16163) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`f9c2f1685`](https://github.com/rustdesk/rustdesk/commit/f9c2f1685733af8373f549b0ab9a9505932dec61) | fix: recover DXGI capture after access loss (#16024) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`f312b5790`](https://github.com/rustdesk/rustdesk/commit/f312b5790941145b11f8a1470c1fcebb16fb337a) | bump hbb_common: cap the answerer's ICE binding requests at 74 | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`4f56d6957`](https://github.com/rustdesk/rustdesk/commit/4f56d6957a49266d36960b50b00d16f3fba03733) | pin the webrtc crate to the fork that exposes max_binding_requests | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`092a961b6`](https://github.com/rustdesk/rustdesk/commit/092a961b629d318fe290eeafac0cd214a1e9deeb) | server: bound unauthenticated connections in number and in time (#16237) | 本次接入 | 第三批 3 项；适配 LAN 握手前连接名额、登录期限和多监听器 ID 隔离 |
| [`0ac2e7fb5`](https://github.com/rustdesk/rustdesk/commit/0ac2e7fb5269b9dbdab85f7213b30d76ba2d49f9) | Avoid Xwayland scans on X11 sessions (#16232) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`f4808b71d`](https://github.com/rustdesk/rustdesk/commit/f4808b71d4aedb894250c13f4a392cc3c13b8e22) | webrtc: encrypt the signalling legs to the rendezvous server, or send no WebRTC signalling (#16224) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`4df7404a6`](https://github.com/rustdesk/rustdesk/commit/4df7404a6c33486a7a50543322fba3e235857803) | webrtc: cap concurrent answerer setups, pin the DTLS fingerprint binding with a test (#16225) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`bedf64c8d`](https://github.com/rustdesk/rustdesk/commit/bedf64c8d3097aa78f7c94f26fb432619ae4d053) | bump hbb_common: cap the message an unauthenticated peer can make us hold | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`fd0fe592e`](https://github.com/rustdesk/rustdesk/commit/fd0fe592eb78f2326c3ea53e6a0f383f8a46b882) | fix(rdev): macos, numpad flag, clear on text keys (#16253) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`01e391739`](https://github.com/rustdesk/rustdesk/commit/01e3917390936bbfa233cbb4d518a8e4e04eeef8) | fix(ci): restore global configurations (#16257) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`0b3a1ddd8`](https://github.com/rustdesk/rustdesk/commit/0b3a1ddd80285c87baad495f79b54d19ef3ba4d9) | rendezvous: cap unauthenticated punches in flight (#16256) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`d4ac2c07b`](https://github.com/rustdesk/rustdesk/commit/d4ac2c07b77b6ee7b442c861b3fc988bb459f0a5) | temporary password: rotate when a peer is let in, not when it leaves (#16080) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`4da167517`](https://github.com/rustdesk/rustdesk/commit/4da167517e27c50fc615485154f6531a737c73ee) | Turkish: translate the three empty entries (#16261) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`04974591b`](https://github.com/rustdesk/rustdesk/commit/04974591b85404b2c6f66ccfaae907b0a60b3b7b) | Refine Portuguese translations for user options (#16264) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`53ec874c3`](https://github.com/rustdesk/rustdesk/commit/53ec874c39e8564a2fb72f4475d19079cec617c1) | Translate terminal clipboard tips to Chinese (#16266) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`5278fcab6`](https://github.com/rustdesk/rustdesk/commit/5278fcab685723099e9950d56cb605807db5aa2a) | fix(cursor): correct native cursor sizing and validate received images (#16213) | 本次接入 | 第四批 4 项；有界解压与游标尺寸／热点校验，保留 LanDesk 旋转；Mac 测试通过，其他宿主待验 |
| [`ef00ed78a`](https://github.com/rustdesk/rustdesk/commit/ef00ed78a750c0dc7527cb7bb9485f7d0e4cc2cb) | Update missing Ukrainian UI translations (#16272) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`ea04f04f9`](https://github.com/rustdesk/rustdesk/commit/ea04f04f9df2096fccba81a133c711166fe93b28) | add hide-elevate-button-in-accept-window (#16271) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`7a367f7cc`](https://github.com/rustdesk/rustdesk/commit/7a367f7cc681dfd96b3621c551d37d5f50ce9118) | bump webrtc fork: one IPv6 host candidate per interface and prefix (#16263) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`97811acbd`](https://github.com/rustdesk/rustdesk/commit/97811acbddf9d1e12c640bff99ea0c731b031291) | Update Dutch translation (#16284) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`dd9b21cf8`](https://github.com/rustdesk/rustdesk/commit/dd9b21cf866d3f67f651f0002445894ab1897530) | server: hold an unauthenticated connection to a small message (#16254) | 本次接入 | 第三批 3 项；认证前 128 KiB 帧限制，禁止登录前发送剪贴板广播 |
| [`a5d4ef97e`](https://github.com/rustdesk/rustdesk/commit/a5d4ef97e897de28faa880c6df6fa863e24ec405) | fix(ws): reject text frames after encryption is enabled (#16295) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`763d4eeb0`](https://github.com/rustdesk/rustdesk/commit/763d4eeb05fbfe2f368a55e24a2ab7214719a926) | bump hbb_common: tungstenite 0.29 forks, read buffer grown as bytes arrive | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`6a0eb9a1f`](https://github.com/rustdesk/rustdesk/commit/6a0eb9a1fda50693a6541d3d6f8c8cac35dcea70) | fix(terminal): preserve trackpad scrolling in alternate screen | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`12f61b1fd`](https://github.com/rustdesk/rustdesk/commit/12f61b1fda041c7429b771f8c9adbb12131e50bd) | Fix/drm rotated cursor (#16242) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`2e7255f08`](https://github.com/rustdesk/rustdesk/commit/2e7255f08333fdaa762486a5faf46b7ca8567772) | fix: suppress heartbeat HTTP retry and TCP proxy logs (#16273) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`458ffe44c`](https://github.com/rustdesk/rustdesk/commit/458ffe44c6103521d1f0f5f0955498195edaa805) | Update Ukrainian README (#16309) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c6a358afb`](https://github.com/rustdesk/rustdesk/commit/c6a358afbe37c518689a6157a8e8cdbd645dcc5d) | Update lang.rs - Splits ambiguous pt into pt-pt and pt-br (#16155) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`7c21b4569`](https://github.com/rustdesk/rustdesk/commit/7c21b4569c6dc51d26dffe4fd94a055e757d7b08) | test(drm): bound the excused shapes at their worst angle, not only on average (#16320) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`68a35e65f`](https://github.com/rustdesk/rustdesk/commit/68a35e65f228244ebdb5d4ce3ad386eca8292672) | fix(unix): ignore SIGPIPE in native Flutter entry (#16322) | 本次接入 | 第二批 20 项 |
| [`b30f781fd`](https://github.com/rustdesk/rustdesk/commit/b30f781fd6749cf484aad6ab4452b392c566157b) | fix: restrict VRAM stall detection to AMD SDK (#16319) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`e424b57fc`](https://github.com/rustdesk/rustdesk/commit/e424b57fcaff2e3e0bdf5c2630c1159422f2568c) | Kx v1 (#16326) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`2e333f64a`](https://github.com/rustdesk/rustdesk/commit/2e333f64a4fe315ca3b61d117e51bfa44e7a7daf) | Update sc.rs (#16314) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`a8ae0d6d6`](https://github.com/rustdesk/rustdesk/commit/a8ae0d6d66b370079e7db8241f5c01ced2fc0dab) | Review and complete pt_PT.rs translation (European Portuguese) (#16311) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`58ff78a82`](https://github.com/rustdesk/rustdesk/commit/58ff78a823fe9ec5fe90f6017261c241656014c2) | Hdr tonemap (#16033) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`f299fb990`](https://github.com/rustdesk/rustdesk/commit/f299fb9906006247863250d7dfaa016f29eef7a4) | fix(clipboard): unix, check file transfer permission on incoming file… (#16333) | 本次接入 | 首批 5 项 |
| [`341193290`](https://github.com/rustdesk/rustdesk/commit/341193290e2b97eb525a5f1b672f59c51dd0d769) | fix(mobile): honor reverse mouse wheel setting (#16337) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`efec124c5`](https://github.com/rustdesk/rustdesk/commit/efec124c52dc79493fe1eb65186d0cf685ef1fae) | Fix, online state, validate the data length (#16339) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`483cc1026`](https://github.com/rustdesk/rustdesk/commit/483cc10266357877dda6b3760e87f6424a4e4a26) | fix(appimage): build AppRun with bounded argument splitting (#16330) | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`417e3bdd2`](https://github.com/rustdesk/rustdesk/commit/417e3bdd2c76f26443ed601b2dcd76d81cfe76d4) | Rename ptbr.rs to pt_BR.rs (#16343) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`134af545a`](https://github.com/rustdesk/rustdesk/commit/134af545ae915c3f5604c16fc8af43eb9a39fa42) | Rename Portuguese module from ptbr to pt_BR (#16342) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`bb924d293`](https://github.com/rustdesk/rustdesk/commit/bb924d2939aa7316fc5612e9d067720484289740) | fix: avoid unnecessary clipboard reads and stale initial sync (#16293) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`e9ddbd8f4`](https://github.com/rustdesk/rustdesk/commit/e9ddbd8f460dac1b30b9815ba324a5dadc8d97b0) | cursor: bound the decoded cursor caches on the Flutter client (#16304) | 本次接入 | 第四批 4 项；内容去重、字节事件与 Flutter 解码缓存回收／重放；不宣称所有会话存储均有界 |
| [`08affc69c`](https://github.com/rustdesk/rustdesk/commit/08affc69c426396557665eef0e2fb0a8831debd7) | Fix clipboard range overflow (#16329) | 本次接入 | 第四批 4 项；文件剪贴板范围／列表绑定与 Windows 坐标溢出；Mac 组件通过，Windows 原生待验 |
| [`17feabbca`](https://github.com/rustdesk/rustdesk/commit/17feabbcabe84869f7236ecf0db5d4b9904ad54f) | fix(windows): allow existing session to foreground (#16349) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`47a2a3c83`](https://github.com/rustdesk/rustdesk/commit/47a2a3c83db1ef03207ec9df5e356cce73b09fa2) | i18n(tw): fill missing Traditional Chinese translations (#16353) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`50258e21e`](https://github.com/rustdesk/rustdesk/commit/50258e21e9222b22664a093c47a2daa093eb444b) | fix(drm): measure the cursor hotspot on drivers without HOTSPOT_X/Y, confirm before publishing (#16122) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`44683d108`](https://github.com/rustdesk/rustdesk/commit/44683d108b11e1eaf58c8675312bddc56a4d779d) | fix(macos): clear Finder progress after clipboard transfers (#16346) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`b5d8b979d`](https://github.com/rustdesk/rustdesk/commit/b5d8b979d8723921902eef9d33c83ff0580fed7b) | i18n(tw): use the Screen Share page label in the voice call hint (#16355) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`8a7662800`](https://github.com/rustdesk/rustdesk/commit/8a76628007018cab739828a5a4ec74fd0a678bda) | fix(clipboard): unix, use the real Windows FILETIME epoch offset (#16366) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`89fcf56c4`](https://github.com/rustdesk/rustdesk/commit/89fcf56c4e49968d0aef637bcd0c7ab63eb1e027) | fix(clipboard): unix, don't let the next file's preload fail a request (#16364) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`be9b96cf6`](https://github.com/rustdesk/rustdesk/commit/be9b96cf6546f8c7dbbdc3d67dee9eb61c2328ad) | Translate voice call instruction to Spanish (#16358) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0d49ead0c`](https://github.com/rustdesk/rustdesk/commit/0d49ead0c37756095572eec74bc7ee7988fc58ea) | fix(drm): turn a captured frame only when the plane did not rotate it (#16345) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`d1722c5d6`](https://github.com/rustdesk/rustdesk/commit/d1722c5d6dc55661c7b02170b0cc4d1ac3cbb298) | fix(linux): use BUS_VIRTUAL for the virtual mouse device (#16382) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`b6b11fd9b`](https://github.com/rustdesk/rustdesk/commit/b6b11fd9b139fc6e2d95b91649747e11a73a2e41) | fix(drm): apply the uinput range on one thread instead of holding a lock across the await (#16362) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`4812a9815`](https://github.com/rustdesk/rustdesk/commit/4812a9815bd3c6a93f3ad903f29504168c4930a1) | AGENTS.md: limit corner-case growth and test bloat | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0c18a8cbc`](https://github.com/rustdesk/rustdesk/commit/0c18a8cbc9c9fa3ce8c7f174fa40abcf9749115e) | fix(flutter): restore multi-window rendering after reconnect (#16383) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`40a4aa34c`](https://github.com/rustdesk/rustdesk/commit/40a4aa34c8d2bd93c5a73c3dd37c4e68cf6a059f) | Don't retry the _pa ipc at a Linux login screen (#16390) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`a7f226020`](https://github.com/rustdesk/rustdesk/commit/a7f2260203befb7e9c70b585219f0f0b5ca57703) | fix(clipboard): unix, don't wrap FILETIMEs past 2554 (#16385) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`9d3ae7acd`](https://github.com/rustdesk/rustdesk/commit/9d3ae7acd2d13e8ce9928ce827e86d13d0f17132) | fix(windows): restore Flutter view visibility after FancyZones placement (#16397) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`fada664df`](https://github.com/rustdesk/rustdesk/commit/fada664df7a294d1d1a9ca3e7cd3637069122f17) | fix(clipboard): unix, keep Windows directories searchable (#16406) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`e5bc204fe`](https://github.com/rustdesk/rustdesk/commit/e5bc204fe4dacc4db9c3cdb1f1338813986c89e7) | fix(wayland): avoid clock waits in PipeWire capture (#16430) | 本次接入 | 第二批 20 项 |
| [`685fa2e4a`](https://github.com/rustdesk/rustdesk/commit/685fa2e4a17f03cae2dfefa10a9091335e576f42) | fix(drm): the startup cache warm does not wake sleeping displays (#16437) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`5406950b0`](https://github.com/rustdesk/rustdesk/commit/5406950b02c102fadb917177d4c7b37615f86340) | fix(macos): open Screen Recording settings from Configure (#16452) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`c9c0b5d0e`](https://github.com/rustdesk/rustdesk/commit/c9c0b5d0efd44b364b31639f3c118e8adc42d98c) | Fix translation for voice call audio capture prompt (#16433) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`e8a865924`](https://github.com/rustdesk/rustdesk/commit/e8a865924bcf3bec628699565a76e5c7583f0ed6) | Updated Polish translation (#16456) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`9f9585ce1`](https://github.com/rustdesk/rustdesk/commit/9f9585ce155a6558f0625eaf8fabfe8827c9a552) | Remove ConfigUpdate handling | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`a916af8f0`](https://github.com/rustdesk/rustdesk/commit/a916af8f000c9501d995d6394639c59baf639695) | Translate voice call audio capture prompt to pt-PT (#16482) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`f0bd880fe`](https://github.com/rustdesk/rustdesk/commit/f0bd880fe7f0e574a1a36811099ba97597429807) | Update nl.rs (#16485) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`25d2c6db5`](https://github.com/rustdesk/rustdesk/commit/25d2c6db5508496e4919118f59e0fe56e9190d24) | log key-up and text injection failures (#16455) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`6da7977a9`](https://github.com/rustdesk/rustdesk/commit/6da7977a9451e0f7d480bd93f95f58024eb21579) | fix(video): defer refresh teardown until hw encoder warms up (#16459) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`1d4abd025`](https://github.com/rustdesk/rustdesk/commit/1d4abd0258bb6678cdd5e2abe3a2af59fd3d7dbe) | fix: resolve HTTP API 407 errors through HTTPS proxies (#16496) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`9b9e5f113`](https://github.com/rustdesk/rustdesk/commit/9b9e5f113a2f6eea90e56f76a99064f52dbd95f3) | fix(wayland): place a portal stream at the only output of its size (#16451) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`3f4bfe535`](https://github.com/rustdesk/rustdesk/commit/3f4bfe535ee020df9470ba8fcdde86cb7f4cf18b) | Fix/wayland input keyboard layout (#16462) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`0bc2473ff`](https://github.com/rustdesk/rustdesk/commit/0bc2473ffe95934408150d48633cd50344c55960) | fix(drm): size a plane-rotated scanout as the mode transposed (#16444) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`001b0e961`](https://github.com/rustdesk/rustdesk/commit/001b0e96173cea4e49f9f7a67bea95a177dd1de3) | Fix/preserve deleted printer (#16500) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`67090d3aa`](https://github.com/rustdesk/rustdesk/commit/67090d3aa14cec95af702aa01e1f3800c0c8e13c) | fix: a refused privacy-mode request no longer turns off another connection's (#16507) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`4411d10f4`](https://github.com/rustdesk/rustdesk/commit/4411d10f450a514c01c83e4f8af7151836300abb) | fix(linux): report the process user as the active user under Flatpak (#16519) | 本次接入 | 第二批 20 项 |
| [`c8532719c`](https://github.com/rustdesk/rustdesk/commit/c8532719c0cfc497c64b9f1e0bc9d981db9137db) | Fix/macos mouse release (#16516) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`0921a7432`](https://github.com/rustdesk/rustdesk/commit/0921a7432ff1c514f9d8faabd1013838641ec241) | feat(update): verify signed update metadata (#15914) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`ccfa714d2`](https://github.com/rustdesk/rustdesk/commit/ccfa714d2e8b982567b5e0f86779c6972e9c7b5e) | Fix Swedish translation typo (#16529) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`109c39bcc`](https://github.com/rustdesk/rustdesk/commit/109c39bccb478170b035ab6821bd5996bf87ddd7) | fix(drm): drop a frame equal to the previous one, as the other capturers do (#16450) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`0b5a3d74d`](https://github.com/rustdesk/rustdesk/commit/0b5a3d74de8e9694f2457db6eb9ab25f30377a3b) | 1.5.1 | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`13e1278b4`](https://github.com/rustdesk/rustdesk/commit/13e1278b4c46eadede9546d3ada1ff9d94b593dd) | fix: auto-login types the OS password only at the logon or lock screen (#16520) | 本次接入 | 第四批 4 项；适配 LAN 能力协商及空闲字段 36；无能力或查询失败时不自动输入密码 |
| [`074006386`](https://github.com/rustdesk/rustdesk/commit/074006386337c1c695f432be99e751a90d4e737f) | Keyboard shortcuts (#14933) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`49a9574f9`](https://github.com/rustdesk/rustdesk/commit/49a9574f97abcfbb967e32273b015a2c0798e16f) | fix(drm): pace the producer to the rate the encoder takes, with the panel refresh as floor (#16423) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`29a160fc7`](https://github.com/rustdesk/rustdesk/commit/29a160fc7e204958cf29ec4b25666991629881e0) | fix(mobile): prevent late mouse-down after floating button release (#16541) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`76ab280ae`](https://github.com/rustdesk/rustdesk/commit/76ab280ae9628c7e788cc7779c493a52f9826796) | fix(terminal): trim the replay buffer when output has no newline (#16545) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`9997b7a3b`](https://github.com/rustdesk/rustdesk/commit/9997b7a3b871fe10c6b8d36652fb2e35afba76f8) | test: remove tests that do not pin user-visible behavior (#16539) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`d011aa3ea`](https://github.com/rustdesk/rustdesk/commit/d011aa3ea6becb5bda2a08ce0374103a85ecce89) | fix(wayland): a pending portal request no longer stalls the server (#16542) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`b1761ee67`](https://github.com/rustdesk/rustdesk/commit/b1761ee676b42078e8275cf70ed2c8349a407b69) | Ci run all dart tests (#16328) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`256dc9bc1`](https://github.com/rustdesk/rustdesk/commit/256dc9bc12c717dea84f6a41371c67acc47edb62) | docs: scope the -p rule to macOS and Windows | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`e910029f5`](https://github.com/rustdesk/rustdesk/commit/e910029f510fc9738424984eb3c1e7c63ede0d2a) | feat: use the configured proxy for WebSocket connections (#16386) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`e614de83f`](https://github.com/rustdesk/rustdesk/commit/e614de83fc616d7a093c9e24acb016963cef1e1c) | fix: read host= from an exe path with non-ASCII characters (#16556) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`c230c5713`](https://github.com/rustdesk/rustdesk/commit/c230c5713977dac3d151a302fe2153d4d2107982) | Update Dutch translation (#16540) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`9c6d3fcb4`](https://github.com/rustdesk/rustdesk/commit/9c6d3fcb4f0fc69fe74bda953e1f2589955eda0c) | Update Italian language (#16551) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`538126d42`](https://github.com/rustdesk/rustdesk/commit/538126d42c6bb7eb5a86dfcad29fc2fef215e596) | Update Portuguese translations for keyboard shortcuts (#16555) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`f1fa432bc`](https://github.com/rustdesk/rustdesk/commit/f1fa432bc80030b887757915f35da051d148a850) | Fix fdroid bridge version (#16560) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`0d36ac0cb`](https://github.com/rustdesk/rustdesk/commit/0d36ac0cba6205db198581cb36146ac1eaba4983) | fix(linux): stop using the window in onWindowClose once GTK destroyed it (#16561) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`f705902ec`](https://github.com/rustdesk/rustdesk/commit/f705902ec3dc2a4fc65d5d8a65cf99c026b8a135) | fix(windows): move installer scripts into protected temp directories (#16554) | 优先待移植 | Windows 安装器脚本／提权交接／服务控制加固；需保留 LanDesk 品牌并验证标准用户、管理员和特殊字符路径，Mac 检查不能替代 |
| [`c0750fb50`](https://github.com/rustdesk/rustdesk/commit/c0750fb50c78740bed42bd82ff99d78af6995263) | fix(client): report one error when both WebRTC race legs fail (#16563) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`392188596`](https://github.com/rustdesk/rustdesk/commit/392188596c28a33638abfcd7514f8d2db99bdb1c) | fix(video): improve clarity after scrolling by re-encoding static frames (#16128) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`e400bb755`](https://github.com/rustdesk/rustdesk/commit/e400bb75546cebf4f72a5ef3cf6e4a3efa2c3aa7) | Enforce lockfile during pub get in build script | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`53996e3c4`](https://github.com/rustdesk/rustdesk/commit/53996e3c404ea5083df0775057e4149e49102084) | Update ru.rs (#16570) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`1042a26de`](https://github.com/rustdesk/rustdesk/commit/1042a26debad1497cf028c3f57d592ee4e5660fe) | Add Flutter code section to README-ID (#16600) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`0cbeb0473`](https://github.com/rustdesk/rustdesk/commit/0cbeb0473099f813c32077d446fef513061b3973) | Forward audio latency environment to Linux user server (#16597) | 本次接入 | 第二批 20 项 |
| [`4b92080e3`](https://github.com/rustdesk/rustdesk/commit/4b92080e3e0970cace2ece563498c64be2dbae6c) | fix(x11): keep the RandR monitors reply alive while iterating it (#16595) | 本次接入 | 首批 5 项 |
| [`bbffc1de5`](https://github.com/rustdesk/rustdesk/commit/bbffc1de5aa33a90d932e47dadaebbca7a7808b8) | fix: bracket a bare IPv6 ID server when deriving the API server (#16624) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`7f5a40194`](https://github.com/rustdesk/rustdesk/commit/7f5a40194715ab2e5896c0c4b83fb66abd8fb502) | Update README-ID translations (#16626) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c7f212df2`](https://github.com/rustdesk/rustdesk/commit/c7f212df2c960fa74bd83d3849a5a7ce7809a047) | fix: warn about insecure custom API server connections (#16616) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`3202d1764`](https://github.com/rustdesk/rustdesk/commit/3202d1764c58902db8c97d803f1f63fa7cbf9e45) | chore(deps): update webpki-roots and rustls-webpki in Cargo.lock (#16639) | 本次接入 | 第二批 20 项 |
| [`4b1821d1f`](https://github.com/rustdesk/rustdesk/commit/4b1821d1ffcc95dc0360d2f0c2834336593f3953) | Update pt pt translation + README.md to include Portuguese (Portugal) (docs/README-PTPT.md) (#16634) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`989beee17`](https://github.com/rustdesk/rustdesk/commit/989beee17fe7c241d2b59c03e974676105f71d00) | Update Italian language (#16633) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c6258f416`](https://github.com/rustdesk/rustdesk/commit/c6258f4166268152185102d0b3a354ef156f7092) | Fix typo in Indonesian translation (#16630) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c29bef18b`](https://github.com/rustdesk/rustdesk/commit/c29bef18bb0d28154cd82a04d52c5f9993c39008) | Update Dutch translations for keyboard shortcuts (#16625) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`8b6103317`](https://github.com/rustdesk/rustdesk/commit/8b61033178c2e3bab50f69c20df17186b53ccdf6) | Update pl.rs (#16588) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`eef109639`](https://github.com/rustdesk/rustdesk/commit/eef1096395517a1ee123e98c3190777d114aee26) | Update fa.rs (#16587) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`b44b71cfa`](https://github.com/rustdesk/rustdesk/commit/b44b71cfabe9898d5eada9b07cb583fe995ed45e) | Fix/download path validation (#16601) | 本次接入 | 第三批 3 项；下载目标、覆盖确认、续传和空目录校验，适配本地目标平台规则 |
| [`2016f48dd`](https://github.com/rustdesk/rustdesk/commit/2016f48dd728b9571001a08f8406bcdfe6a6c0d4) | fix(file-transfer): keyboard navigation in the desktop file list (#16642) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`ce54e33c7`](https://github.com/rustdesk/rustdesk/commit/ce54e33c71716c4cd1e93c02b4e21555cd923694) | fix(ffmpeg): handle QSV encoder stalls and undersized buffers (#16303) | 暂缓，未宣称同步 | 安装器／原生依赖／打包修改；需对应平台构建，不能只复制补丁就宣称生效 |
| [`4e93a41ec`](https://github.com/rustdesk/rustdesk/commit/4e93a41ecc3848abf88feb9a364cd1e7c7af570f) | Tune MediaCodec static refresh budgets (#16579) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`bd9262397`](https://github.com/rustdesk/rustdesk/commit/bd9262397208c509ea97af61f0d44621ef25611c) | fix(linux): match the xrandr output name at the start of its line (#16590) | 本次接入 | 第二批 20 项 |
| [`f010d33ca`](https://github.com/rustdesk/rustdesk/commit/f010d33ca622fbb7a1d8c722acb726b494f6212e) | fix(android): wheel scrolling from the controller does not reach Android peers (#16409) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`2b6fedfc8`](https://github.com/rustdesk/rustdesk/commit/2b6fedfc8e8e8ba35ec764dbcc81210cb5343333) | fix(windows): protect installer handoff and use native service control (#16562) | 优先待移植 | Windows 安装器脚本／提权交接／服务控制加固；需保留 LanDesk 品牌并验证标准用户、管理员和特殊字符路径，Mac 检查不能替代 |
| [`d97351ad7`](https://github.com/rustdesk/rustdesk/commit/d97351ad73058ad92d0f1dd41ed99a8fe3122655) | Custom websocket port (#16658) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`3ec041644`](https://github.com/rustdesk/rustdesk/commit/3ec041644d6c18a6fbf8b8291bf60ef71614e513) | fix(linux): gtk sudo shows no false "Sorry, try again." and retries with sudo-rs (#16652) | 本次接入 | 第二批 20 项 |
| [`828d1101a`](https://github.com/rustdesk/rustdesk/commit/828d1101afd2e656eb1c1d18511009bdf5336238) | chore(deps): pin hwcodec to rustdesk-org/hwcodec#47 | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`398364fa1`](https://github.com/rustdesk/rustdesk/commit/398364fa187d0559c39462366a61dd0b25652e78) | fix(ios): keep background music playing during remote sessions (#16660) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`eb6c32bd5`](https://github.com/rustdesk/rustdesk/commit/eb6c32bd572df88f2771a8d034a55f26b2615b71) | l10n(tr): fill missing shortcut and API server translations (#16669) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`25d274227`](https://github.com/rustdesk/rustdesk/commit/25d27422733920926cff0c27f8e37f8fdbd26288) | fix(lang): pick the Kazakh and Georgian translations from the system locale (#16670) | 本次接入 | 第二批 20 项 |
| [`f7b0af78c`](https://github.com/rustdesk/rustdesk/commit/f7b0af78cbbfc90aa5403fbace93b4fa99c1abbb) | fix(lang): pick Traditional Chinese for Hong Kong and Macao system locales (#16671) | 本次接入 | 第二批 20 项 |
| [`106f700be`](https://github.com/rustdesk/rustdesk/commit/106f700be4a9a924a60e29783520cd43a7811239) | fix(linux): read Debian's GDM config when checking for a Wayland login screen (#16674) | 本次接入 | 第二批 20 项 |
| [`01e1323e5`](https://github.com/rustdesk/rustdesk/commit/01e1323e51d998084698a1b1e09b42040bda157d) | fix(linux): keep listing resolutions after an interlaced xrandr mode (#16672) | 本次接入 | 第二批 20 项 |
| [`21c488b6c`](https://github.com/rustdesk/rustdesk/commit/21c488b6ce80159484015dfd0f58ef7748a24f6c) | fix(linux): recognize a login screen whose greeter uses another nologin path (#16675) | 本次接入 | 第二批 20 项 |
| [`4d37f00af`](https://github.com/rustdesk/rustdesk/commit/4d37f00af964e8a43fb2239d8599ff8690e4d906) | fix(client): invalidate auto FPS state when updating FPS limits (#16283) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`ed6a1acce`](https://github.com/rustdesk/rustdesk/commit/ed6a1acce896fb165f2642aa13b609166d57a734) | feat(address-book): add a toolbar button to open the web console (#16680) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`c8a4e0680`](https://github.com/rustdesk/rustdesk/commit/c8a4e0680cb553b5547cfccfb859316688078cd6) | fix(linux): capture the default output's monitor for remote audio (#16681) | 本次接入 | 第二批 20 项 |
| [`8814503e0`](https://github.com/rustdesk/rustdesk/commit/8814503e06a63431ea6d16b1c24ec40ee1a84a21) | fix(linux): pick up pulsectl's default source fix for voice calls (#16685) | 本次接入 | 第二批 20 项 |
| [`1297da6d1`](https://github.com/rustdesk/rustdesk/commit/1297da6d186e58d9096be24072ae3998cdbbf8fe) | Update Korean language (#16687) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`f96a44a01`](https://github.com/rustdesk/rustdesk/commit/f96a44a0190e5e5ad79ceed298efbbc7a58a03db) | chore: update webpki-roots to latest Mozilla root store (#16713) | 本次接入 | 第二批 20 项 |
| [`182356ee8`](https://github.com/rustdesk/rustdesk/commit/182356ee8bbcb3a3c19754687660eb0d0404b0b6) | fix(linux): load peers when the app dir is unset (#16698) | 本次接入 | 第二批 20 项；适配 LAN 最近设备／收藏，未恢复云地址簿 |
| [`a5e986401`](https://github.com/rustdesk/rustdesk/commit/a5e986401c09587f20a56273b0361f0cd8a5dd3d) | Update Dutch translations (#16702) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`59f2953c9`](https://github.com/rustdesk/rustdesk/commit/59f2953c94b8373f124dc38d4fd0635098f7c5cd) | fix(windows): name the privacy window executable explicitly (#16711) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`eb2390245`](https://github.com/rustdesk/rustdesk/commit/eb239024503160707cca87ba6cef5fbfb8fa3f0d) | fix(lang): keep the {} value and the meaning in four translations (#16701) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`894f53283`](https://github.com/rustdesk/rustdesk/commit/894f5328352ecb0b44d195f02ce2c30f6b48be91) | Update API server connection tips in Portuguese (#16734) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`d0a1af8c5`](https://github.com/rustdesk/rustdesk/commit/d0a1af8c51d821fa8d9f16ea24fa35694ca64646) | feat(android): transfer files directly through SAF folders (#16644) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`350966b33`](https://github.com/rustdesk/rustdesk/commit/350966b331bb873650668549b3fa4a42e81e6a81) | Add trusted-device V2 with legacy upgrade compatibility (#16548) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`bb8083cb2`](https://github.com/rustdesk/rustdesk/commit/bb8083cb2fb245c2c56a52b21047bd22aa78e43f) | udpate hbb_common (#16737) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`04360797a`](https://github.com/rustdesk/rustdesk/commit/04360797addc71138ea30e6c630c073811d9a1d5) | Update Dutch translations in nl.rs (#16739) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`acda5a73e`](https://github.com/rustdesk/rustdesk/commit/acda5a73e2c5b953beb3f040e45f5ec0ea96eba0) | Update Italian language (#16747) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`df9df7e91`](https://github.com/rustdesk/rustdesk/commit/df9df7e91494b37b4b55775f4b92a91dd13822a1) | Update pt_PT.rs (#16748) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`c8cb6fb50`](https://github.com/rustdesk/rustdesk/commit/c8cb6fb50943fc9b34e5c608e91f6f19fad26301) | Update ko.rs (#16749) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`5217f32a1`](https://github.com/rustdesk/rustdesk/commit/5217f32a123b100899596f77e771d0141e32e307) | Improve Portuguese translations in pt_BR.rs (#16752) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3cb027a37`](https://github.com/rustdesk/rustdesk/commit/3cb027a372f6bc65f22d3a53e79f0d92f694e48d) | Update Hebrew translation (#16690) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`eba0a6e55`](https://github.com/rustdesk/rustdesk/commit/eba0a6e5520b9f74b0cd0da297fa6e82c9aa96b3) | fix(web): preserve peer card clicks with semantics enabled (#16709) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`0aaf3a02b`](https://github.com/rustdesk/rustdesk/commit/0aaf3a02bfb9d82d6e688871a03e4a64e6b08928) | finish translations | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`e1ca09766`](https://github.com/rustdesk/rustdesk/commit/e1ca09766cc97eaaba5e350114431189b109be7d) | refact(update): change the pub key for metadata (#16758) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`cda384733`](https://github.com/rustdesk/rustdesk/commit/cda384733779aac32a80183fefeb7b88dba9edec) | Strip all whitespace from pasted IDs, not only spaces (#16762) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`ef827fdb3`](https://github.com/rustdesk/rustdesk/commit/ef827fdb34aef13cb37826b9efc62e8b9a28f1b0) | update ios minver | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`33a154a5d`](https://github.com/rustdesk/rustdesk/commit/33a154a5d7502419381dc601aff1e4b0c660054d) | Fix F-Droid 1.5.0 build by disabling lockfile enforcement (#16673) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`0d6265bb2`](https://github.com/rustdesk/rustdesk/commit/0d6265bb26b8127061ea14c7a5e5c602ddec8778) | fix(ios): adopt the UIScene life cycle (#16776) | 已有对应实现 | AppDelegate 已用 FlutterImplicitEngineDelegate，Info.plist 已配置 SceneDelegate |
| [`eab27cc24`](https://github.com/rustdesk/rustdesk/commit/eab27cc249b217f8662a7dac0c7d974501173303) | Build Windows custom client packers in CI (#16781) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`3b7e2cebd`](https://github.com/rustdesk/rustdesk/commit/3b7e2cebd9303a43eecb9bc96921548df846f45d) | fix: restore readiness after service restart and macOS update (#16780) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`94c321d05`](https://github.com/rustdesk/rustdesk/commit/94c321d05ce02ee73304e6cf99187e2d4d96e409) | fix(ci): fail Windows signing on error and retry transient HTTP failures | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`c5201d600`](https://github.com/rustdesk/rustdesk/commit/c5201d600bb2c05a941ce9228cec030b2c60d7a2) | Allow trusted devices for direct IP connections (#16778) | 暂缓，未宣称同步 | 相关源码尚有结构分歧；须适配并补目标平台验证，当前不是已同步状态 |
| [`fa611556f`](https://github.com/rustdesk/rustdesk/commit/fa611556f84a36d1d1484d335dae2d1ec251b787) | Clarify auto login requirements in Portuguese (#16792) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`82301f177`](https://github.com/rustdesk/rustdesk/commit/82301f1776ef8ab68229c8ad5199d6aedcc3b96b) | Fix/windows install directory confirmation (#16783) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`23e5bb471`](https://github.com/rustdesk/rustdesk/commit/23e5bb471a040d62f0a6ad52591fb30784265b73) | finish translations | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`f9586e171`](https://github.com/rustdesk/rustdesk/commit/f9586e171427c1b078b4f3fe81a5729a5d21aa5c) | fix(android): prevent crash on large clipboard payload (>1MB) (#16767) | 本次接入 | 首批 5 项 |
| [`29d1ab26a`](https://github.com/rustdesk/rustdesk/commit/29d1ab26a1c48161b3ac4714ae5a17461cb777c1) | fix(sciter): avoid double DPI scaling of main window minimum size (#16824) | 不适用于现有流程 | 涉及已移除的公网／云账号／更新／旧 UI 或原版 ID 认证路径；不机械恢复 |
| [`4ec4ec3d1`](https://github.com/rustdesk/rustdesk/commit/4ec4ec3d14e5e191b1bbc53003bd37f9357c7d11) | fix(ci): build macOS arm64 with Flutter 3.44 (#16821) | 暂缓，未宣称同步 | 依赖／特性或子模块关联；保留固定 LAN fork，需另做依赖闭包与平台构建验证 |
| [`6aec3069a`](https://github.com/rustdesk/rustdesk/commit/6aec3069aec486ad7df07429a0a1ee411fc8d73a) | fix(ios): follow system dark mode on launch screen (#16816) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`037b8787f`](https://github.com/rustdesk/rustdesk/commit/037b8787fe66a915c0899ccebf481eb82ceb5a18) | Clarify that "Forget Password" clears the saved password (#16826) | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`a85ad89ff`](https://github.com/rustdesk/rustdesk/commit/a85ad89ffceea89d1d863e2b350cdc63cca04be6) | feat: request approval (#16784) | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`41f182e63`](https://github.com/rustdesk/rustdesk/commit/41f182e636ba7c5072df9fac9abf4cea197e20f2) | fix(android): copy captured frames before the Image is released (#16827) | 本次接入 | 首批 5 项 |
| [`beeeef14f`](https://github.com/rustdesk/rustdesk/commit/beeeef14f0a61bd622aacf042b4396bdeaed9b61) | fix(wayland): pass on an unclassified capture error instead of "x11 expected" | 本次接入 | 第二批 20 项 |
| [`47740e8fd`](https://github.com/rustdesk/rustdesk/commit/47740e8fd73f539cfe58aa5aa3bb0d95e2b09c30) | Update reference from AGENTS.md to @AGENTS.md | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`df529f149`](https://github.com/rustdesk/rustdesk/commit/df529f149af9c78f1b7553d560e07683a36ec22f) | remove CLAUDE.md | 本轮不接入 | 上游文档、翻译或 CI 元数据；保留 LanDesk 品牌、已有非空翻译及本机发布流程 |
| [`661befbb6`](https://github.com/rustdesk/rustdesk/commit/661befbb6de697dae8f4914a416687b3fd42db6c) | test: drop the Material 3 case from the approval arrow alignment test | 暂缓，未宣称同步 | 涉及 Flutter／原生宿主／输入与界面；需保留当前皮肤、虚拟键盘和会话改造后验证 |
| [`55786aaa5`](https://github.com/rustdesk/rustdesk/commit/55786aaa5709ac0a450aabcf06f9d1fee3119908) | perf(android): hand the captured frame over instead of copying it again (#16835) | 本次接入 | 首批 5 项 |
