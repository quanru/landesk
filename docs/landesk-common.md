# 为什么保留 landesk-common

2026-11-03 核对，主仓库的 `libs/hbb_common` 子模块指向 `quanru/landesk-common`，固定提交 `262dd7619b3da8ec87f3d7a1bb59762eb782ea65`，位于 `localdesk/main` 分支。只看该仓库默认 `main` 分支会漏掉 LanDesk 的修改。

相对直接上游 `zibo-chen/hbb_common` 的 `main`，这个固定分支包含 5 个本地提交，修改 `src/config.rs`、`src/lan.rs`、`src/tcp.rs` 等共享实现：限制目标为私有 IP、校验 TCP 出站目标、移除云账号绑定与穿透配置，以及调整默认画质和帧率。

因此当前有必要保留 fork。直接把子模块 URL 改为 RustDesk 或 SubnetDesk 上游，会失去主应用依赖的修改，甚至无法获取当前固定提交。保留 fork 并不意味着继续把所有客户端功能塞进共享层；新增客户端专属逻辑仍应优先放入主仓库 `libs/base`。

未来只有在这些修改已被上游接收，或经过明确的迁移与连接回归验证后，才能删除 fork。当前不改子模块来源、不移动指针，也不为命名整洁重写依赖历史。

可核对的来源：

- [主仓库子模块](https://github.com/quanru/landesk/blob/main/.gitmodules)
- [实际使用分支](https://github.com/quanru/landesk-common/tree/localdesk/main)
- [与直接上游比较](https://github.com/quanru/landesk-common/compare/zibo-chen:main...localdesk/main)
