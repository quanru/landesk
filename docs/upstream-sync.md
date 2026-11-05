# RustDesk 上游同步约定

## 主线与备份

`main` 从本次迁移起维护官方 RustDesk 原生架构上的 LanDesk；`legacy` 固定保留迁移前的本地主线 `758fef56b0d9daf56c44b6bb43cf0e667a8ad262`，不再接收新功能。它包含迁移前 GitHub `main` 的 `74e43f92f8f9917727d00342161b855a6798ea6f`，以及尚未推送的 8 个旧架构修复/审计提交。迁移分支保留以便追溯。

本次源码采用官方 `55786aaa5709ac0a450aabcf06f9d1fee3119908`，Git 历史也将该提交纳入祖先。初次迁移先提交已经构建验证的官方快照及产品改造，再用一次保留当前树的合并记录快照来源；这是一次性的历史接续，不表示自动合并验证通过。**后续同步禁止使用 `-s ours`、`-X ours` 或整目录覆盖来跳过上游修改。**

固定版本记录在 `tools/migration/native-baseline.json`。`libs/hbb_common` 直接引用官方子模块及官方提交，不新增 common fork。切换主线不代表软件发版；尚未完成的平台验收继续以迁移台账为准。

## 每次同步

先保证工作区干净，并检查 remote 确为官方地址。同步默认在现有主线进行，只有用户明确要求才另建分支。

```sh
git status --short
git remote get-url rustdesk
# 应为 https://github.com/rustdesk/rustdesk.git
git fetch rustdesk master
python3 tools/migration/upstream-status.py --target rustdesk/master > /tmp/landesk-upstream-impact.json
```

报告检查基线祖先关系、子模块记录，列出新提交数量、上游变更文件、产品差异文件及重叠文件。目标使用报告中的完整 SHA，避免检查期间远端移动。没有新提交时无需合并。报告只读，不会触发构建、网络配置或 CI。

审阅 `git log <旧基线>..<目标SHA>` 和 `git diff <旧基线> <目标SHA>`，重点看认证、权限、消息协议、依赖、子模块与平台构建变化。正常合并：

```sh
git merge --no-ff --no-commit <目标SHA>
# 审阅并逐项解决冲突，不批量选择 ours/theirs。
git submodule update --init --recursive
```

检查上游工作流是否重新引入 push、pull_request 或 schedule 自动运行；没有单独授权时保持手动触发，不在解决冲突时恢复自动发版。子模块采用目标官方 gitlink，若上游变更必须审阅对应范围；客户端特有逻辑放 `libs/base`，尽量不改 common。

解决后更新 JSON 中的 `upstream_app`、`upstream_common`，补充本次验证记录，再提交合并。若中止，使用正常 `git merge --abort`，前提是开始时工作区干净且没有并行写入；不要清理其他人的 WIP。

## 控制维护成本

- LAN 产品策略集中于 `src/landesk.rs`、`src/landesk_native_policy.rs`；共享入口保留薄调用。上游新增连接入口仍须检查是否绕开产品策略，Git 无冲突不代表语义正确。
- 主题、虚拟按键与侧栏尽量放独立 Flutter 模块；上游页面只接入模块。优先修改独立模块，避免整页格式化、复制官方类和长期维护两套传输栈。
- Web 网关、浏览器客户端是产品额外维护面；上游协议变更必须同时核对 Rust 网关和 TypeScript 消息定义，重新生成并验证浏览器客户端。
- 原生输入补丁、品牌、签名和依赖兼容补丁仍会产生冲突。上游已解决相同问题时删除本地补丁，而不是继续叠加。
- 一个同步批次使用一个明确官方基线，通常按周检查或在发版前检查；认证/权限等重要修复单独及时评估。这里未设置定时任务。

## 验证与提交

按报告中的文件和依赖影响选定检查，全部本机构建/测试遵守 dev-gate；不默认触发远端付费 CI。LAN 地址限制、密码/被控端批准、权限拒绝、公网功能禁用是产品策略回归重点。涉及输入时验证虚拟键按下/释放、修饰键、窗口概览；涉及 UI 时真实运行并截图；跨协议变化覆盖原生与浏览器连接。平台特有改动在对应环境验证，不用 Mac 结果冒充 Windows/Linux。

合并后再运行同步检查，确认新基线属于 HEAD；保存检查结果与验证范围。Git 推送前核对无签名私钥、profile、缓存或安装包进入提交。`release_ready` 不能因合并成功改为 true；已知验收缺口见 `docs/validation/native-migration-progress-2026-11-04.md`。

这个流程保证来源、差异和验证范围可追溯，**不保证今后没有冲突或零回归**。上游调整认证、协议、Flutter 或平台构建时仍需要人工适配。
