# 开源许可与发布记录

LanDesk 基于 RustDesk、SubnetDesk 修改。保留根目录 LICENCE、NOTICE、
文件级版权声明及依赖许可证。项目不限制用户依 AGPL 修改、再分发或获取源码。

## 获取和构建

已发布构建的固定源码和校验入口：[releases.md](releases.md)。

```sh
git clone --recurse-submodules https://github.com/quanru/landesk.git
cd landesk
git checkout <releases.md 中的完整或短提交>
git submodule update --init --recursive
```

- Rust 依赖由 `Cargo.lock` 固定；`cargo fetch --locked` 获取，
  `cargo vendor --locked` 可生成带许可证文件的本地 vendor 目录。
- Flutter 使用 3.44.1；依赖由 `flutter/pubspec.lock` 固定，
  在 flutter 目录运行 `flutter pub get`。Flutter 自带的 LicensePage
  展示 Flutter 收集的许可证，**不覆盖 Rust/C/C++ 全部依赖**。
- 本地库清单见 `vcpkg.json`、`res/vcpkg/` 和构建脚本。
  当前开发机沿用预装 codec/libsodium 库；历史库的确切源码、补丁、
  版本与编译配置尚未全部追溯，不能声称已提供完整可重建依赖集合。
- Mac/iOS 构建脚本在 `tools/localdesk/`；执行记录见
  `docs/validation/release-2026-10-28.md`。脚本的环境变量必须按本机配置，
  文档中的开发机路径不是分发者必须使用的路径。
- `package-source.py <commit> <output.tar.gz>` 导出已提交文件及固定子模块，
  不包含本地配置、证书、私钥或用户数据。生成的桥接文件按构建脚本重新生成。
- Apple 安装需要接收者自己的签名环境；不发布维护者的个人签名私钥。
  这并不能代替对 AGPL 第 6 条安装信息义务的具体适用性判断。

## 仍需完成的发布核对

1. 追溯已发布二进制中 Rust、Dart、native 库的精确来源，保留其许可文本，
   补充所需依赖源码和构建配置；在干净环境重建验证。
2. 全部发布使用唯一构建号、固定 Git 提交、固定子模块及构建记录。
3. 检查远程用户是否能显著访问源码入口（第 13 条）。新代码在桌面和移动端
   “关于”提供入口，但旧构建没有该入口；不能将新源码视为旧二进制已更新。
4. Apple 分发条款兼容性未获得确认，见下文。公开 App Store 或外部测试
   不应以“上传成功”为依据宣称通过许可审查。

## Apple 分发：待确认，不是已通过

2026-10-28 核对的官方资料：

- [TestFlight Terms](https://www.apple.com/legal/internet-services/itunes/testflight/)
- [Developer Program License Agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)
- [GNU FAQ](https://www.gnu.org/licenses/gpl-faq.html)
- 本仓库 LICENCE 第 6、10、12、13 条。

Apple 条款含使用与转让等限制，并涉及平台签名/分发机制；须确认其对
LanDesk 本体、开源组件例外和用户再分发/修改权利的实际影响。
自定义 EULA 或公开 GitHub 不自动消除冲突，不能擅自给上游代码添加
“Apple 例外”。如果确有冲突，需取得必要权利人的授权或采用兼容分发方式。

现有 TestFlight 76/77 的上传事实不等于合法性结论。本次没有撤回既有构建、
替用户接受新协议或提交外部审核。需要合格的开源许可专业人士确认此项。
