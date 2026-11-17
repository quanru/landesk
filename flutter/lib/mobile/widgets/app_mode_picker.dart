import 'package:flutter/material.dart';
import '../../models/app_mode_model.dart';

class AppModePicker extends StatefulWidget {
  final Future<List<AppWindow>> Function() load;
  final Future<void> Function(AppWindow, bool, double) select;
  final bool chinese;
  const AppModePicker(
      {super.key,
      required this.load,
      required this.select,
      required this.chinese});

  @override
  State<AppModePicker> createState() => _AppModePickerState();
}

class _AppModePickerState extends State<AppModePicker> {
  late Future<List<AppWindow>> _windows = widget.load();
  bool _fit = true;
  double _contentScale = 1.0;
  int? _opening;
  String? _error;
  String text(String zh, String en) => widget.chinese ? zh : en;

  Future<void> select(AppWindow window) async {
    setState(() {
      _opening = window.id;
      _error = null;
    });
    try {
      await widget.select(window, _fit, _contentScale);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(text('选择 App', 'Choose an app'),
                            style: theme.textTheme.titleLarge)),
                    IconButton(
                        tooltip: text('刷新', 'Refresh'),
                        onPressed: _opening != null
                            ? null
                            : () {
                                setState(() {
                                  _windows = widget.load();
                                  _error = null;
                                });
                              },
                        icon: const Icon(Icons.refresh)),
                    IconButton(
                        tooltip: text('关闭', 'Close'),
                        onPressed: _opening != null
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 8),
                  Text(text('当前显示器上可见的窗口', 'Visible windows on this display'),
                      style: theme.textTheme.bodyMedium),
                  SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _fit,
                      title: Text(text('适配手机比例', 'Fit to this device')),
                      subtitle: Text(text('会调整窗口，退出时恢复大小',
                          'Resizes the window; restores it when you exit')),
                      onChanged: _opening != null
                          ? null
                          : (value) => setState(() => _fit = value)),
                  if (_fit) ...[
                    Text(text('内容大小', 'Content size')),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      for (final scale in [1.0, 1.25, 1.5])
                        ChoiceChip(
                            label: Text('${(scale * 100).round()}%'),
                            selected: _contentScale == scale,
                            onSelected: _opening != null
                                ? null
                                : (_) {
                                    setState(() => _contentScale = scale);
                                  }),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        text('放大内容会减少窗口可显示的区域；部分 App 有最小尺寸限制。',
                            'Larger content shows less of the window. Some apps enforce a minimum size.'),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                  ],
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error))),
                  FutureBuilder<List<AppWindow>>(
                      future: _windows,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return SingleChildScrollView(
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Text('${snapshot.error}')));
                        }
                        if (!snapshot.hasData) {
                          return const SizedBox(
                              height: 140,
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        final windows = snapshot.data!;
                        if (windows.isEmpty) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(text('此显示器上暂无可用窗口',
                                  'No available windows on this display')));
                        }
                        return ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: windows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final window = windows[index];
                              return Material(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListTile(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      minVerticalPadding: 12,
                                      leading:
                                          const Icon(Icons.web_asset_outlined),
                                      title: Text(window.app,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      subtitle: window.title.isEmpty
                                          ? null
                                          : Text(window.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                      trailing: _opening == window.id
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Icon(Icons.chevron_right),
                                      enabled: _opening == null,
                                      onTap: () => select(window)));
                            });
                      }),
                  const SizedBox(height: 12),
                  Text(
                      text('窗口聚焦仍共享桌面画面，其他窗口遮挡时也会显示。',
                          'Focus mode still shares the desktop. Overlapping windows remain visible.'),
                      style: theme.textTheme.bodySmall),
                ]))));
  }
}
