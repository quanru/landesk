# 获取对应版本源码 / Release source

无需账号、付费或向维护者申请，可从以下链接获取源码。源码按仓库内
`LICENCE`（AGPL v3）及各依赖自身许可证提供。允许依许可证修改和再分发。

| 已提供的二进制 | 构建源码提交 | 源码快照 |
| --- | --- | --- |
| macOS 1.3.0 (75)，GitHub `v1.3.0-preview.20261028` | `88d5d5c18` | [Mac 源码及子模块](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261028/landesk-macos-75-source.tar.gz) |
| iOS TestFlight 1.3.0 (76) | `44dd99b6b` | [iOS 76 源码及子模块](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261028/landesk-ios-76-source.tar.gz) |
| iOS TestFlight 1.3.0 (77)；本机素雅主题 Mac 更新 | `ad0f04c5b` | [素雅主题源码及子模块](https://github.com/quanru/landesk/releases/download/v1.3.0-preview.20261028/landesk-ios-77-source.tar.gz) |

历史构建是在提交前后的工作树构建，以上提交按执行记录匹配源码；文档提交
不影响应用代码。它们不是通过可重现构建证明的二进制逐字节匹配。
Mac 构建号 75 被本机更新复用：公开 ZIP 对应第一行，本机更新对应第三行。
今后的发布必须使用唯一构建号，并在构建前固定提交。

这些归档包含全部 Git 跟踪文件及固定版本的 `libs/hbb_common`，附带
`SOURCE_REVISIONS.json`。GitHub 自动生成的 Source code ZIP 不包含子模块，
请优先使用上面的归档。校验值见同一 Release 的 `SOURCE_SHA256SUMS.txt`。

**依赖范围说明：这些是项目源码快照，不能把它们称为已审计完整的
Corresponding Source。** Cargo/pub/native 第三方依赖尚未全部随归档打包；
获取方式、构建环境和未完成项见 [构建与许可说明](README.md)。

[最新开发源码](https://github.com/quanru/landesk/tree/localdesk/main)
不代替上面特定构建的源码。
