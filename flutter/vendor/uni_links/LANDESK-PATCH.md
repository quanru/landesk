# LanDesk 本地补丁

来源：https://github.com/rustdesk-org/uni_links ，提交 `f416118d843a7e9ed117c7bb7bdc2deda5a9e86f` 的 `uni_links/`。原始许可证见 LICENSE。

仅删除 Android v1 `PluginRegistry.Registrar` 注册入口，以支持 Flutter 3.44.1。保留 v2 FlutterPlugin / ActivityAware、初始链接和新 Intent 处理。未改 Dart 或 iOS 实现。未复制上游示例与测试工程。
