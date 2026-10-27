import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'remote_shortcut.dart';
import 'virtual_key_editor.dart';

class _KeySpot {
  _KeySpot(this.config, this.x, this.y);
  _KeySpot.single(RemoteShortcut shortcut, this.x, this.y)
      : config = VirtualKeyConfig(shortcut.title, [shortcut]);
  VirtualKeyConfig config;
  double x, y; // normalized coordinates, 0..1

  Map<String, dynamic> toJson() => {
        ...config.toJson(),
        'x': x,
        'y': y,
      };

  factory _KeySpot.fromJson(Map<String, dynamic> j) => _KeySpot(
        VirtualKeyConfig.fromJson(j),
        (j['x'] as num?)?.toDouble() ?? .5,
        (j['y'] as num?)?.toDouble() ?? .5,
      );
}

/// Place outside the remote pointer/gesture listeners so key touches stay local.
/// Short tap sends the remote key; long press enters layout edit mode.
/// Layout is local to the iPad and persists across sessions.
class CustomKeyOverlay extends StatefulWidget {
  const CustomKeyOverlay(
      {super.key,
      required this.send,
      this.isMac = true,
      this.profileId = 'default'});
  final Future<void> Function(RemoteShortcut) send;
  final bool isMac;
  final String profileId;

  @override
  State<CustomKeyOverlay> createState() => _CustomKeyOverlayState();
}

class _CustomKeyOverlayState extends State<CustomKeyOverlay>
    with WidgetsBindingObserver {
  bool _cancelled = false;
  String get _filename =>
      'virtual_keys_v3/${base64Url.encode(utf8.encode(widget.profileId))}_${widget.isMac ? 'mac' : 'linux'}.json';
  bool _sending = false;
  bool _loaded = false;
  Future<void> _pendingSave = Future.value();
  late List<_KeySpot> _spots = _defaults();
  bool _edit = false;
  bool _visible = true;

  List<_KeySpot> _defaults() => [
        _KeySpot.single(const RemoteShortcut('Esc', 'VK_ESCAPE'), .02, .28),
        _KeySpot.single(const RemoteShortcut('Tab', 'VK_TAB'), .02, .40),
        _KeySpot.single(
            RemoteShortcut(widget.isMac ? '⌘ Tab' : 'Alt Tab', 'VK_TAB',
                command: widget.isMac, alt: !widget.isMac),
            .02,
            .52),
        _KeySpot.single(
            RemoteShortcut('Copy', 'VK_C',
                command: widget.isMac, ctrl: !widget.isMac),
            .02,
            .64),
        _KeySpot.single(
            RemoteShortcut('Paste', 'VK_V',
                command: widget.isMac, ctrl: !widget.isMac),
            .83,
            .28),
        _KeySpot.single(const RemoteShortcut('↑', 'VK_UP'), .83, .40),
        _KeySpot.single(const RemoteShortcut('↓', 'VK_DOWN'), .83, .52),
        _KeySpot.single(const RemoteShortcut('Enter', 'VK_ENTER'), .83, .64),
        _KeySpot.single(
            RemoteShortcut(widget.isMac ? '⌘ Space' : 'Super Space', 'VK_SPACE',
                command: true),
            .83,
            .78),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancelled = true;
  }

  @override
  void dispose() {
    _cancelled = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/$_filename');

  Future<void> _load() async {
    try {
      var file = await _file();
      if (!await file.exists()) {
        file = File(
            '${(await getApplicationSupportDirectory()).path}/rustdesk_mobile_virtual_keys_v2_${widget.isMac ? 'mac' : 'linux'}.json');
      }
      if (!await file.exists()) return;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rows = (data['spots'] as List).cast<Map<String, dynamic>>();
      if (!mounted || rows.length > 40) return;
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
    final destination = _file();
    final data = jsonEncode({
      'spots': _spots.map((s) => s.toJson()).toList(),
      'visible': _visible,
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        final file = await destination;
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(data, flush: true);
        await temporary.rename(file.path);
      } catch (e) {
        debugPrint('CustomKeyOverlay layout save failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save key layout')));
        }
      }
    });
    return _pendingSave;
  }

  Future<void> _send(VirtualKeyConfig config) async {
    if (_sending) return;
    _cancelled = false;
    setState(() => _sending = true);
    try {
      await sendRemoteMacro(config.steps, config.delayMs, widget.send,
          cancelled: () => !mounted || _cancelled);
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

  Future<void> _editShortcut(int? index) async {
    final result = await showDialog<VirtualKeyEditResult>(
      context: context,
      builder: (_) => VirtualKeyEditor(
        initial: index == null
            ? VirtualKeyConfig(
                'Key', [const RemoteShortcut('Key', 'VK_ESCAPE')])
            : _spots[index].config,
        canDelete: index != null,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.delete) {
        _spots.removeAt(index!);
      } else if (index == null) {
        _spots.add(_KeySpot(result.config!, .5, .5));
      } else {
        _spots[index].config = result.config!;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
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
                    onTap: _sending
                        ? null
                        : () {
                            setState(() {
                              if (_edit) {
                                _edit = false;
                              } else {
                                _visible = !_visible;
                              }
                            });
                            _save();
                          },
                    onLongPress: _sending
                        ? null
                        : () => setState(() {
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
          if (_edit && !_sending)
            Positioned(
                top: 6,
                left: 60,
                child: Material(
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                        tooltip: 'Add key',
                        icon: const Icon(Icons.add),
                        onPressed: _spots.length < 40
                            ? () => _editShortcut(null)
                            : null))),
          if (_sending)
            Positioned(
                top: 6,
                left: 60,
                child: FilledButton.icon(
                    onPressed: () => setState(() => _cancelled = true),
                    icon: const Icon(Icons.stop),
                    label: Text(_cancelled ? 'Stopping…' : 'Stop macro'))),
          if (_visible)
            ...List.generate(_spots.length, (i) {
              final spot = _spots[i];
              final size = math.min(spot.config.size,
                  math.min(bounds.maxWidth, bounds.maxHeight));
              final width = math.max(0.0, bounds.maxWidth - size);
              final height = math.max(0.0, bounds.maxHeight - size);
              return Positioned(
                left: spot.x.clamp(0.0, 1.0).toDouble() * width,
                top: spot.y.clamp(0.0, 1.0).toDouble() * height,
                child: GestureDetector(
                  key: ValueKey('virtual-key-$i'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress: (_edit || _sending)
                      ? null
                      : () => setState(() => _edit = true),
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
                  onTap: () => _edit ? _editShortcut(i) : _send(spot.config),
                  child: Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _edit
                          ? Colors.deepOrange.withOpacity(.85)
                          : Colors.black.withOpacity(spot.config.opacity),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(spot.config.title,
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
