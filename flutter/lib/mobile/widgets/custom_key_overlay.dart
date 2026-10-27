import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'remote_shortcut.dart';

class _KeySpot {
  _KeySpot(this.shortcut, this.x, this.y);
  RemoteShortcut shortcut;
  double x, y; // normalized coordinates, 0..1

  Map<String, dynamic> toJson() => {
        ...shortcut.toJson(),
        'x': x,
        'y': y,
      };

  factory _KeySpot.fromJson(Map<String, dynamic> j) => _KeySpot(
        RemoteShortcut.fromJson(j),
        (j['x'] as num?)?.toDouble() ?? .5,
        (j['y'] as num?)?.toDouble() ?? .5,
      );
}

/// Place outside the remote pointer/gesture listeners so key touches stay local.
/// Short tap sends the remote key; long press enters layout edit mode.
/// Layout is local to the iPad and persists across sessions.
class CustomKeyOverlay extends StatefulWidget {
  const CustomKeyOverlay({super.key, required this.send, this.isMac = true});
  final Future<void> Function(RemoteShortcut) send;
  final bool isMac;

  @override
  State<CustomKeyOverlay> createState() => _CustomKeyOverlayState();
}

class _CustomKeyOverlayState extends State<CustomKeyOverlay> {
  static const _size = 49.0;
  String get _filename =>
      'rustdesk_mobile_virtual_keys_v2_${widget.isMac ? 'mac' : 'linux'}.json';
  bool _sending = false;
  bool _loaded = false;
  Future<void> _pendingSave = Future.value();
  late List<_KeySpot> _spots = _defaults();
  bool _edit = false;
  bool _visible = true;

  List<_KeySpot> _defaults() => [
        _KeySpot(const RemoteShortcut('Esc', 'VK_ESCAPE'), .02, .28),
        _KeySpot(const RemoteShortcut('Tab', 'VK_TAB'), .02, .40),
        _KeySpot(
            RemoteShortcut(widget.isMac ? '⌘ Tab' : 'Alt Tab', 'VK_TAB',
                command: widget.isMac, alt: !widget.isMac),
            .02,
            .52),
        _KeySpot(
            RemoteShortcut('Copy', 'VK_C',
                command: widget.isMac, ctrl: !widget.isMac),
            .02,
            .64),
        _KeySpot(
            RemoteShortcut('Paste', 'VK_V',
                command: widget.isMac, ctrl: !widget.isMac),
            .83,
            .28),
        _KeySpot(const RemoteShortcut('↑', 'VK_UP'), .83, .40),
        _KeySpot(const RemoteShortcut('↓', 'VK_DOWN'), .83, .52),
        _KeySpot(const RemoteShortcut('Enter', 'VK_ENTER'), .83, .64),
        _KeySpot(
            RemoteShortcut(widget.isMac ? '⌘ Space' : 'Super Space', 'VK_SPACE',
                command: true),
            .83,
            .78),
      ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/$_filename');

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rows = (data['spots'] as List).cast<Map<String, dynamic>>();
      if (!mounted || rows.length != 9) return;
      setState(() {
        _spots = rows.map(_KeySpot.fromJson).toList();
        _visible = data['visible'] != false;
      });
    } catch (e) {
      debugPrint('CustomKeyOverlay using default layout: $e');
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() {
    final data = jsonEncode({
      'spots': _spots.map((s) => s.toJson()).toList(),
      'visible': _visible,
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        final file = await _file();
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(data, flush: true);
        await temporary.rename(file.path);
      } catch (e) {
        debugPrint('CustomKeyOverlay layout save failed: $e');
      }
    });
    return _pendingSave;
  }

  Future<void> _send(RemoteShortcut shortcut) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.send(shortcut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send remote shortcut')),
        );
      }
      debugPrint('Remote shortcut failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editShortcut(int index) async {
    final item = _spots[index].shortcut;
    final title = TextEditingController(text: item.title);
    String selectedKey = item.key;
    bool ctrl = item.ctrl,
        alt = item.alt,
        shift = item.shift,
        command = item.command;
    final result = await showDialog<RemoteShortcut>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
                title: const Text('Edit remote shortcut'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: title,
                      maxLength: 10,
                      decoration:
                          const InputDecoration(labelText: 'Button label')),
                  DropdownButtonFormField<String>(
                    value: remoteKeyLabels.containsKey(selectedKey)
                        ? selectedKey
                        : 'VK_ESCAPE',
                    decoration: const InputDecoration(labelText: 'Key'),
                    items: remoteKeyLabels.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) =>
                        update(() => selectedKey = value ?? 'VK_ESCAPE'),
                  ),
                  CheckboxListTile(
                      dense: true,
                      title: const Text('Ctrl'),
                      value: ctrl,
                      onChanged: (v) => update(() => ctrl = v ?? false)),
                  CheckboxListTile(
                      dense: true,
                      title: const Text('Alt'),
                      value: alt,
                      onChanged: (v) => update(() => alt = v ?? false)),
                  CheckboxListTile(
                      dense: true,
                      title: const Text('Shift'),
                      value: shift,
                      onChanged: (v) => update(() => shift = v ?? false)),
                  CheckboxListTile(
                      dense: true,
                      title: const Text('Command / Super'),
                      value: command,
                      onChanged: (v) => update(() => command = v ?? false)),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          dialogContext,
                          RemoteShortcut(
                              title.text.trim().isEmpty
                                  ? 'Key'
                                  : title.text.trim(),
                              selectedKey,
                              ctrl: ctrl,
                              alt: alt,
                              shift: shift,
                              command: command)),
                      child: const Text('Save')),
                ],
              )),
    );
    title.dispose();
    if (result == null || !mounted) return;
    setState(() => _spots[index].shortcut = result);
    await _save();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final width = math.max(0.0, bounds.maxWidth - _size);
        final height = math.max(0.0, bounds.maxHeight - _size);
        if (!_loaded) return const SizedBox.expand();
        return Stack(children: [
          // Always-available small toggle (even with the keys hidden).
          Positioned(
              top: 6,
              left: 6,
              child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_edit) {
                          _edit = false;
                        } else {
                          _visible = !_visible;
                        }
                      });
                      _save();
                    },
                    onLongPress: () => setState(() {
                      _visible = true;
                      _edit = !_edit;
                    }),
                    child: Semantics(
                        label: _edit
                            ? 'Finish editing keys'
                            : 'Toggle virtual keys',
                        button: true,
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _edit
                                  ? Icons.check
                                  : (_visible
                                      ? Icons.gamepad
                                      : Icons.gamepad_outlined),
                              color: Colors.white,
                              size: 21,
                            ))),
                  ))),
          if (_visible)
            ...List.generate(_spots.length, (i) {
              final spot = _spots[i];
              return Positioned(
                left: spot.x.clamp(0.0, 1.0).toDouble() * width,
                top: spot.y.clamp(0.0, 1.0).toDouble() * height,
                child: GestureDetector(
                  key: ValueKey('virtual-key-$i'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress:
                      _edit ? null : () => setState(() => _edit = true),
                  onPanUpdate: _edit
                      ? (details) {
                          setState(() {
                            spot.x = ((spot.x * width + details.delta.dx) /
                                    math.max(width, 1))
                                .clamp(0.0, 1.0)
                                .toDouble();
                            spot.y = ((spot.y * height + details.delta.dy) /
                                    math.max(height, 1))
                                .clamp(0.0, 1.0)
                                .toDouble();
                          });
                        }
                      : null,
                  onPanEnd: _edit ? (_) => _save() : null,
                  onTap: () => _edit ? _editShortcut(i) : _send(spot.shortcut),
                  child: Container(
                    width: _size,
                    height: _size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _edit
                          ? Colors.deepOrange.withOpacity(.85)
                          : Colors.black.withOpacity(.56),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(spot.shortcut.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }),
        ]);
      });
}
