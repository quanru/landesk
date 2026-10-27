import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'remote_shortcut.dart';

String virtualKeyText(String text) => text;

class VirtualKeyConfig {
  VirtualKeyConfig(this.title, List<RemoteShortcut> steps,
      {this.size = 49, this.opacity = .56, this.delayMs = 100})
      : steps = List.unmodifiable(steps);
  final String title;
  final List<RemoteShortcut> steps;
  final double size, opacity;
  final int delayMs;

  Map<String, dynamic> toJson() => {
        'title': title,
        'steps': steps.map((s) => s.toJson()).toList(),
        'size': size,
        'opacity': opacity,
        'delayMs': delayMs,
      };

  factory VirtualKeyConfig.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] == null
        ? [RemoteShortcut.fromJson(json)]
        : (json['steps'] as List)
            .map((s) => RemoteShortcut.fromJson(s as Map<String, dynamic>))
            .toList();
    if (steps.isEmpty ||
        steps.length > 20 ||
        steps.any((s) => !remoteKeyLabels.containsKey(s.key))) {
      throw const FormatException('Invalid shortcut sequence');
    }
    double bounded(String name, double fallback, double min, double max) {
      final value = (json[name] as num?)?.toDouble() ?? fallback;
      return value.isFinite ? value.clamp(min, max).toDouble() : fallback;
    }

    return VirtualKeyConfig(json['title'] as String? ?? 'Key', steps,
        size: bounded('size', 49, 44, 120),
        opacity: bounded('opacity', .56, .15, 1),
        delayMs: bounded('delayMs', 100, 0, 2000).round());
  }
}

class VirtualKeyEditResult {
  const VirtualKeyEditResult.save(this.config) : delete = false;
  const VirtualKeyEditResult.delete()
      : config = null,
        delete = true;
  final VirtualKeyConfig? config;
  final bool delete;
}

class VirtualKeyEditor extends StatefulWidget {
  const VirtualKeyEditor(
      {super.key,
      required this.initial,
      required this.canDelete,
      this.translate = virtualKeyText});
  final VirtualKeyConfig initial;
  final bool canDelete;
  final String Function(String) translate;
  @override
  State<VirtualKeyEditor> createState() => _VirtualKeyEditorState();
}

class _VirtualKeyEditorState extends State<VirtualKeyEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _steps = widget.initial.steps.toList();
  late double _size = widget.initial.size, _opacity = widget.initial.opacity;
  late int _delay = widget.initial.delayMs;
  int _selected = 0;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _change(
      {String? key, bool? ctrl, bool? alt, bool? shift, bool? command}) {
    final s = _steps[_selected];
    setState(() => _steps[_selected] = RemoteShortcut('', key ?? s.key,
        ctrl: ctrl ?? s.ctrl,
        alt: alt ?? s.alt,
        shift: shift ?? s.shift,
        command: command ?? s.command));
  }

  String _label(RemoteShortcut s) => [
        if (s.ctrl) 'Ctrl',
        if (s.alt) 'Alt',
        if (s.shift) 'Shift',
        if (s.command) 'Cmd/Super',
        remoteKeyLabels[s.key] ?? s.key,
      ].join(' + ');

  void _move(int delta) {
    setState(() {
      final step = _steps.removeAt(_selected);
      _selected += delta;
      _steps.insert(_selected, step);
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_selected];
    final t = widget.translate;
    final available = MediaQuery.of(context).size.height -
        MediaQuery.of(context).viewInsets.bottom;
    Widget pane(List<Widget> children) => SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children));
    Widget keyControls() =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DropdownButtonFormField<String>(
              key: ValueKey('step-$_selected-${step.key}'),
              value: step.key,
              decoration: InputDecoration(
                  labelText: "${t('Key for step')} ${_selected + 1}"),
              items: remoteKeyLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => _change(key: v)),
          Wrap(spacing: 8, children: [
            FilterChip(
                label: const Text('Ctrl'),
                selected: step.ctrl,
                onSelected: (v) => _change(ctrl: v)),
            FilterChip(
                label: const Text('Alt'),
                selected: step.alt,
                onSelected: (v) => _change(alt: v)),
            FilterChip(
                label: const Text('Shift'),
                selected: step.shift,
                onSelected: (v) => _change(shift: v)),
            FilterChip(
                label: const Text('Cmd / Super'),
                selected: step.command,
                onSelected: (v) => _change(command: v)),
          ]),
        ]);
    return DefaultTabController(
        length: 3,
        child: AlertDialog(
          title: Text(
              t(widget.canDelete ? 'Edit key / macro' : 'Add key / macro')),
          content: SizedBox(
              width: 420,
              height: math.max(150, math.min(430, available - 240)),
              child: Column(children: [
                TabBar(
                    labelColor: Theme.of(context).colorScheme.secondary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurface,
                    onTap: (_) => FocusScope.of(context).unfocus(),
                    tabs: [
                      Tab(text: t('Key settings')),
                      Tab(text: t('Key appearance')),
                      Tab(text: t('Macro steps')),
                    ]),
                Expanded(
                    child: TabBarView(children: [
                  pane([
                    TextField(
                        controller: _title,
                        maxLength: 16,
                        decoration:
                            InputDecoration(labelText: t('Button label'))),
                    keyControls(),
                  ]),
                  pane([
                    Text("${t('Size')}: ${_size.round()} pt"),
                    Slider(
                        key: const ValueKey('key-size'),
                        value: _size,
                        min: 44,
                        max: 120,
                        divisions: 76,
                        label: '${_size.round()} pt',
                        onChanged: (v) => setState(() => _size = v)),
                    Text(
                        "${t('Background opacity')}: ${(_opacity * 100).round()}%"),
                    Slider(
                        key: const ValueKey('key-opacity'),
                        value: _opacity,
                        min: .15,
                        max: 1,
                        divisions: 85,
                        label: '${(_opacity * 100).round()}%',
                        onChanged: (v) => setState(() => _opacity = v)),
                  ]),
                  pane([
                    Text(t(
                        'Steps run once, from top to bottom. Each step releases all its keys.')),
                    for (var i = 0; i < _steps.length; i++)
                      ListTile(
                          dense: true,
                          selected: i == _selected,
                          title: Text('${i + 1}. ${_label(_steps[i])}'),
                          onTap: () => setState(() => _selected = i)),
                    Wrap(spacing: 8, children: [
                      TextButton.icon(
                          onPressed: _steps.length < 20
                              ? () => setState(() {
                                    _steps.add(
                                        const RemoteShortcut('', 'VK_ENTER'));
                                    _selected = _steps.length - 1;
                                  })
                              : null,
                          icon: const Icon(Icons.add),
                          label: Text(t('Add step'))),
                      IconButton(
                          tooltip: t('Move step up'),
                          onPressed: _selected > 0 ? () => _move(-1) : null,
                          icon: const Icon(Icons.arrow_upward)),
                      IconButton(
                          tooltip: t('Move step down'),
                          onPressed: _selected + 1 < _steps.length
                              ? () => _move(1)
                              : null,
                          icon: const Icon(Icons.arrow_downward)),
                      IconButton(
                          tooltip: t('Delete step'),
                          onPressed: _steps.length > 1
                              ? () => setState(() {
                                    _steps.removeAt(_selected);
                                    _selected = 0;
                                  })
                              : null,
                          icon: const Icon(Icons.delete_outline)),
                    ]),
                    keyControls(),
                    if (_steps.length > 1) ...[
                      Text("${t('Wait between steps')}: $_delay ms"),
                      Slider(
                          value: _delay.toDouble(),
                          min: 0,
                          max: 2000,
                          divisions: 40,
                          label: '$_delay ms',
                          onChanged: (v) => setState(() => _delay = v.round())),
                    ],
                  ]),
                ])),
              ])),
          actions: [
            if (widget.canDelete)
              TextButton(
                  onPressed: () => Navigator.pop(
                      context, const VirtualKeyEditResult.delete()),
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  child: Text(t('Delete key'))),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('Cancel'))),
            ElevatedButton(
                onPressed: () => Navigator.pop(
                    context,
                    VirtualKeyEditResult.save(VirtualKeyConfig(
                        _title.text.trim().isEmpty ? 'Key' : _title.text.trim(),
                        _steps,
                        size: _size,
                        opacity: _opacity,
                        delayMs: _delay))),
                child: Text(t('Save'))),
          ],
        ));
  }
}
