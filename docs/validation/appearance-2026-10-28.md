# 设置外观选择与导航优化

生产代码：2705504e8；macOS / iOS 构建号 83。

- 桌面和移动端共用 ThemeModeSelector：图标、文字、勾选标记，保留禁用策略及主题持久化调用。
- 移动端直接在设置页选择主题，删除单独的主题选择弹窗。
- 宽屏横排，窄屏及大字号纵排，不强行截断标签。
- 桌面设置导航改为最小高度，允许换行；增加选中语义和圆角命中反馈。

验证：12 项相关 widget 测试通过，包括亮/暗、375/800 宽度、1/2 倍字体、选择回调、禁用控件和设置表单交互。目标文件分析无错误，桌面设置页保留原有 unused 声明及弃用提示。

macOS release 编译、签名兼容检查和安装通过，读取安装版本为 83。iOS unsigned archive 编译成功，未签名/安装/上传 TestFlight；原有 launch image placeholder 警告仍在。

截图：dist/screenshots/theme83/appearance-{light,dark}.png 及 appearance-{light,dark}-mobile.png。由正式组件渲染，英文示例、预览字体；不是原生设置页截图。已检查亮暗桌面及窄屏布局。

CUA 能取得首页截图，但设置入口自动点击仍未切页，包括延长按下时间后的尝试，原因未确认。未将 widget 验证当作完整原生交互验收。
