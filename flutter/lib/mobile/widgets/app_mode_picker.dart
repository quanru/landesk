import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../models/app_mode_model.dart';

class AppModePicker extends StatefulWidget {
  final Future<List<AppWindow>> Function() load;
  final Future<Uint8List?> Function(AppWindow)? loadThumbnail;
  final Future<void> Function(AppWindow, bool, double) select;
  final bool chinese;
  final int? selectedId;
  const AppModePicker(
      {super.key,
      required this.load,
      required this.select,
      required this.chinese,
      this.loadThumbnail,
      this.selectedId});

  @override
  State<AppModePicker> createState() => _AppModePickerState();
}

class _AppModePickerState extends State<AppModePicker> {
  late Future<List<AppWindow>> _windows = _loadWindows();
  final _previews = <int, MemoryImage>{};
  bool _fit = true;
  double _contentScale = 1.0;
  int? _opening;
  String? _error;
  String text(String zh, String en) => widget.chinese ? zh : en;

  Future<List<AppWindow>> _loadWindows() {
    final request = widget.load();
    unawaited(request.then(
      (windows) => _loadThumbnails(windows, request),
      onError: (Object error) {},
    ));
    return request;
  }

  Future<void> _loadThumbnails(
      List<AppWindow> windows, Future<List<AppWindow>> request) async {
    final load = widget.loadThumbnail;
    if (load == null) return;
    for (final window in windows.where((window) => window.thumbnailAvailable)) {
      if (!mounted || !identical(_windows, request)) return;
      final bytes = await load(window);
      if (!mounted || !identical(_windows, request)) return;
      if (bytes != null) {
        setState(() => _previews[window.id] = MemoryImage(bytes));
      }
    }
  }

  void _clearPreviews() {
    for (final image in _previews.values) {
      unawaited(image.evict());
    }
    _previews.clear();
  }

  @override
  void dispose() {
    _clearPreviews();
    super.dispose();
  }

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

  Widget windowButton(AppWindow window, double width) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = widget.selectedId == window.id;
    final opening = _opening == window.id;
    final hasTitle = window.title.isNotEmpty && window.title != window.app;
    final label = hasTitle ? '${window.app} · ${window.title}' : window.app;
    final thumbnail = _previews[window.id];
    final placeholder =
        Icon(Icons.web_asset_outlined, color: colors.onSurfaceVariant);
    return SizedBox(
      width: width,
      child: Semantics(
        selected: selected,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: Material(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: selected ? colors.primary : colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _opening == null ? () => select(window) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (thumbnail == null)
                            Center(child: placeholder)
                          else
                            Image(
                              image: thumbnail,
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                              errorBuilder: (_, __, ___) =>
                                  Center(child: placeholder),
                            ),
                          if (opening || selected)
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colors.primaryContainer,
                                  foregroundColor: colors.onPrimaryContainer,
                                  child: opening
                                      ? const SizedBox.square(
                                          dimension: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check, size: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(window.app,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge),
                        if (hasTitle)
                          Text(window.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget displaySettings() => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        enabled: _opening == null,
        title: Text(text('显示设置', 'Display settings')),
        leading: const Icon(Icons.tune),
        children: [
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
                        : (_) => setState(() => _contentScale = scale)),
            ]),
            const SizedBox(height: 8),
          ],
          Text(
            text('其他窗口挡在所选窗口前面时，也会出现在画面里。',
                'Windows in front of the selected window remain visible.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                      : () => setState(() {
                            _clearPreviews();
                            _windows = _loadWindows();
                            _error = null;
                          }),
                  icon: const Icon(Icons.refresh)),
              IconButton(
                  tooltip: text('关闭', 'Close'),
                  onPressed: _opening != null
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close)),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FutureBuilder<List<AppWindow>>(
                future: _windows,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('${snapshot.error}');
                  if (!snapshot.hasData) {
                    return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final windows = snapshot.data!;
                  if (windows.isEmpty) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(text('此显示器上暂无可用窗口',
                            'No available windows on this display')));
                  }
                  return LayoutBuilder(builder: (context, constraints) {
                    const spacing = 12.0;
                    final columns = ((constraints.maxWidth + spacing) / 155)
                        .floor()
                        .clamp(1, 4);
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final window in windows)
                          windowButton(window, width)
                      ],
                    );
                  });
                },
              ),
            ),
            displaySettings(),
          ],
        ),
      ),
    );
  }
}
