import 'package:flutter/material.dart';
import 'custom_key_overlay.dart';
import 'remote_shortcut.dart';
import 'preview_translations.dart';

void main() => runApp(const PreviewApp());

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});
  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  bool dark = false;
  bool chinese = true;
  ThemeData theme(Brightness brightness) => ThemeData(
        useMaterial3: false,
        brightness: brightness,
        colorScheme: brightness == Brightness.light
            ? const ColorScheme.light(
                primary: Colors.blue, secondary: Color(0xff0071ff))
            : const ColorScheme.dark(
                primary: Colors.blue, secondary: Color(0xff0071ff)),
        scaffoldBackgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xff18191e),
        dialogBackgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xff18191e),
        dialogTheme: DialogTheme(
            elevation: 15,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0071ff),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)))),
      );
  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Preview(
          chinese: chinese,
          toggleLanguage: () => setState(() => chinese = !chinese),
          toggleTheme: () => setState(() => dark = !dark)));
}

class Preview extends StatefulWidget {
  const Preview(
      {super.key,
      required this.chinese,
      required this.toggleLanguage,
      required this.toggleTheme});
  final bool chinese;
  final VoidCallback toggleLanguage, toggleTheme;
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final events = <String>[];
  String profile = 'Mac A';
  int taps = 0;
  int pans = 0;
  double zoom = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
            title:
                Text(widget.chinese ? '虚拟按键 · 测试页面' : 'Virtual keys · preview'),
            actions: [
              IconButton(
                  tooltip: '中文 / English',
                  onPressed: widget.toggleLanguage,
                  icon: const Icon(Icons.translate)),
              IconButton(
                  tooltip: '明亮 / 深色',
                  onPressed: widget.toggleTheme,
                  icon: const Icon(Icons.brightness_6)),
              DropdownButton<String>(
                  value: profile,
                  items: ['Mac A', 'Mac B']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (p) => setState(() => profile = p!)),
            ]),
        body: SafeArea(
            child: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => taps++),
            onScaleUpdate: (details) => setState(() {
              pans++;
              zoom = details.scale;
            }),
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  widget.chinese
                      ? '仅测试界面和输入事件\n未连接远程主机'
                      : 'UI + event sequence only\nNo remote host connected',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Text(
                  'Canvas taps: $taps · moves: $pans · scale: ${zoom.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Text(events.join('\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 16)),
              const SizedBox(height: 24),
              Text(
                  widget.chinese
                      ? '长按按键进入编辑，拖动调整位置。\n点击 + 添加按键，点击 ✓ 完成。Mac A / B 用于测试独立布局。'
                      : 'Long press a key to edit. Drag to move.\nTap ✓ to finish. Use + to add keys / macros. Switch Mac A / B to test profiles.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
          ),
          CustomKeyOverlay(
              key: ValueKey(profile),
              profileId: profile,
              translate: (text) =>
                  widget.chinese ? (previewTranslations[text] ?? text) : text,
              send: (shortcut) async {
                if (!mounted) return;
                await sendRemoteShortcut(shortcut, (key, down,
                    {required ctrl,
                    required alt,
                    required shift,
                    required command}) async {
                  if (!mounted) return;
                  setState(() {
                    if (events.length >= 8) events.removeAt(0);
                    events.add('$key ${down ? "DOWN" : "UP"}  '
                        '${ctrl ? "Ctrl " : ""}${alt ? "Alt " : ""}${shift ? "Shift " : ""}${command ? "Cmd" : ""}');
                  });
                });
              }),
        ])),
      );
}
