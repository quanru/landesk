# 设备列表空状态与侧栏状态排版

生产代码 bca0c8813；本机 macOS 1.3.0 (84)。

- 搜索筛选结果为空时增加说明和清除搜索按钮，同时清空搜索控制器与响应式查询值。
- 分组为空时提供切换列表/分组说明；最近访问、收藏、发现列表共用可滚动空状态布局。
- 侧栏服务状态改为标题下的独立一行，避免长状态标签挤压“你的桌面”。

验证：8 项 widget 测试通过，覆盖亮暗、320×240 / 800×600、1 / 2 倍字号，以及滚动后点击操作。peers_view 与新组件分析无问题；desktop_home_page 无分析错误或警告，保留 17 项既有 info 提示。macOS release 编译与同身份签名安装成功，安装版本读回 84。

原生截图 dist/screenshots/empty84/home-native.png，确认新的侧栏状态布局与就绪提示。search-light.png / search-dark.png 是正式组件预览，使用英文示例与预览字体，不是原生搜索结果截图。

验证边界：未完成真实有设备列表的搜索—清除端到端验证。CUA Tab 未显示控件焦点变化，原生交互限制仍在。源码中的 canBeBlocked/shouldBeBlocked 已固定为 false，不能据此断定自动点击失败原因。

本轮旧版本截图出现一次“Unable to communicate with the background service”，但同时 21118 仍有 LocalDesk 进程监听；安装后截图显示就绪。未改变服务协议或健康状态逻辑，不宣称通信异常已根治。未更新 iOS 构建或 TestFlight。
