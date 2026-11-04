import 'dart:convert';

import 'package:flutter/material.dart';

import 'remote_shortcut.dart';

const windowOverviewOption = 'window-overview-shortcut';
const macWindowOverview = RemoteShortcut('All windows', 'VK_UP', ctrl: true);
const windowsWindowOverview = RemoteShortcut(
  'All windows',
  'VK_TAB',
  command: true,
);

RemoteShortcut? decodeWindowOverview(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic> ||
        !remoteKeyLabels.containsKey(json['key'])) {
      return null;
    }
    return RemoteShortcut.fromJson(json);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

/// Linux desktops and compositors have no shared window-overview shortcut.
/// Saving a binding never sends it; the rail button explicitly triggers it.
class WindowOverviewSettings extends StatefulWidget {
  const WindowOverviewSettings({super.key, this.initial, required this.onSave});

  final RemoteShortcut? initial;
  final Future<void> Function(RemoteShortcut) onSave;

  @override
  State<WindowOverviewSettings> createState() => _WindowOverviewSettingsState();
}

class _WindowOverviewSettingsState extends State<WindowOverviewSettings> {
  late String _key = widget.initial?.key ?? 'VK_TAB';
  late bool _ctrl = widget.initial?.ctrl ?? false;
  late bool _alt = widget.initial?.alt ?? false;
  late bool _shift = widget.initial?.shift ?? false;
  late bool _super = widget.initial?.command ?? true;
  bool _saving = false;
  bool _failed = false;

  RemoteShortcut get _shortcut => RemoteShortcut(
    'All windows',
    _key,
    ctrl: _ctrl && _key != 'VK_CONTROL',
    alt: _alt && _key != 'VK_MENU',
    shift: _shift && _key != 'VK_SHIFT',
    command: _super && _key != 'Meta',
  );

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(_shortcut);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    String t(String zh, String en) => chinese ? zh : en;
    final colors = Theme.of(context).colorScheme;
    Widget modifier(
      String label,
      bool value,
      String key,
      ValueChanged<bool> change,
    ) => FilterChip(
      label: Text(label),
      selected: value && _key != key,
      onSelected: _saving || _key == key
          ? null
          : (value) => setState(() => change(value)),
    );
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(t('所有窗口快捷键', 'Window overview shortcut')),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(
                    '请选择远端 Linux 已配置的窗口总览快捷键。Hyprland 需要先配置对应功能和按键绑定。',
                    'Match the window overview binding on your Linux desktop. '
                        'Hyprland needs an overview feature and key binding configured first.',
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _key,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t('按键', 'Key')),
                  items: remoteKeyLabels.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.key == 'Meta' ? 'Super' : entry.value,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (key) => setState(() => _key = key!),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    modifier('Ctrl', _ctrl, 'VK_CONTROL', (v) => _ctrl = v),
                    modifier('Alt', _alt, 'VK_MENU', (v) => _alt = v),
                    modifier('Shift', _shift, 'VK_SHIFT', (v) => _shift = v),
                    modifier('Super', _super, 'Meta', (v) => _super = v),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    '仅保存到当前连接；保存后点击“所有窗口”触发。',
                    'Saved for this connection. Tap All windows to trigger it.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_failed) ...[
                  const SizedBox(height: 12),
                  Text(
                    t('保存失败，请重试。', 'Could not save. Please try again.'),
                    style: TextStyle(color: colors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(t('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? t('保存中…', 'Saving…') : t('保存', 'Save')),
          ),
        ],
      ),
    );
  }
}
