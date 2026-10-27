import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'remote_shortcut.dart';
import 'virtual_key_editor.dart';
import 'virtual_mouse_controls.dart';

class _KeySpot {
  _KeySpot(this.config, this.x, this.y);
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
      this.write,
      this.mouseScroll,
      this.isMac = true,
      this.profileId = 'default',
      this.translate = virtualKeyText});
  final Future<void> Function(RemoteShortcut) send;
  final RemoteKeyWriter? write;
  final Future<void> Function(int)? mouseScroll;
  final bool isMac;
  final String profileId;
  final String Function(String) translate;

  @override
  State<CustomKeyOverlay> createState() => _CustomKeyOverlayState();
}

class _CustomKeyOverlayState extends State<CustomKeyOverlay>
    with WidgetsBindingObserver {
  bool _cancelled = false;
  RemoteAppSwitcher? _switcher;
  final Set<String> _modifiers = {};

  Future<void> _finishSwitch() async {
    try {
      await _switcher?.finish();
    } catch (e) {
      debugPrint('Could not release application switcher: $e');
    }
    if (mounted) setState(() {});
  }

  String get _filename =>
      'virtual_keys_v3/${base64Url.encode(utf8.encode(widget.profileId))}_${widget.isMac ? 'mac' : 'linux'}.json';
  final Map<String, Offset> _mousePositions = {};
  bool _sending = false;
  bool _loaded = false;
  Future<void> _pendingSave = Future.value();
  late List<_KeySpot> _spots = _defaults();
  bool _edit = false;
  bool _visible = true;

  List<_KeySpot> _defaults() {
    _KeySpot key(String title, String code, double x, double y,
            {bool command = false, bool ctrl = false, bool alt = false}) =>
        _KeySpot(
            VirtualKeyConfig(
                title,
                [
                  RemoteShortcut(title, code,
                      command: command, ctrl: ctrl, alt: alt)
                ],
                size: 64,
                opacity: .60),
            x,
            y);
    return [
      key('Esc', 'VK_ESCAPE', .02, .10),
      key('Tab', 'VK_TAB', .94, .25),
      key(widget.isMac ? '⌘ Tab' : 'Alt Tab', 'VK_TAB', .82, .25,
          command: widget.isMac, alt: !widget.isMac),
      key('Copy', 'VK_C', .94, .39, command: widget.isMac, ctrl: !widget.isMac),
      key('Paste', 'VK_V', .94, .53,
          command: widget.isMac, ctrl: !widget.isMac),
      key('↑', 'VK_UP', .02, .40),
      key('↓', 'VK_DOWN', .02, .54),
      key('Enter', 'VK_ENTER', .82, .85),
      key(widget.isMac ? '⌘ Space' : 'Super Space', 'VK_SPACE', .58, .85,
          command: true),
      key('Space', 'VK_SPACE', .70, .85),
      key('Back', 'VK_BACK', .94, .85),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.write != null) {
      _switcher = RemoteAppSwitcher(widget.write!, isMac: widget.isMac);
    }
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancelled = true;
      _modifiers.clear();
      _finishSwitch();
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    _finishSwitch();
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
        final positions = data['mousePositions'];
        if (positions is Map) {
          for (final id in ['mouse', 'wheel']) {
            final p = positions[id];
            if (p is List && p.length == 2 && p.every((v) => v is num && v.isFinite)) {
              _mousePositions[id] = Offset((p[0] as num).toDouble().clamp(0, 1),
                  (p[1] as num).toDouble().clamp(0, 1));
            }
          }
        }
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
      'mousePositions': _mousePositions.map((id, p) => MapEntry(id, [p.dx, p.dy])),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(widget.translate('Could not save key layout'))));
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
      final first = config.steps.first;
      final switching = config.steps.length == 1 &&
          first.key == 'VK_TAB' &&
          (widget.isMac
              ? first.command || _modifiers.contains('Cmd')
              : first.alt || _modifiers.contains('Opt'));
      if (switching && _switcher != null) {
        await _switcher!.next();
        return;
      }
      await _finishSwitch();
      await sendRemoteMacro(
          config.steps,
          config.delayMs,
          (step) => widget.send(RemoteShortcut(step.title, step.key,
              ctrl: step.ctrl || _modifiers.contains('Ctrl'),
              alt: step.alt || _modifiers.contains('Opt'),
              shift: step.shift,
              command: step.command || _modifiers.contains('Cmd'))),
          cancelled: () => !mounted || _cancelled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(widget.translate('Could not send remote shortcut'))),
        );
      }
      debugPrint('Remote shortcut failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editShortcut(int? index) async {
    await _finishSwitch();
    final result = await showDialog<VirtualKeyEditResult>(
      context: context,
      builder: (_) => VirtualKeyEditor(
        initial: index == null
            ? VirtualKeyConfig(
                'Key', [const RemoteShortcut('Key', 'VK_ESCAPE')])
            : _spots[index].config,
        canDelete: index != null,
        translate: widget.translate,
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
          if (_visible && widget.mouseScroll != null)
            Positioned.fill(child: VirtualMouseControls(
              scroll: widget.mouseScroll!,
              translate: widget.translate, editing: _edit, positions: _mousePositions,
              onPositionEnd: _save,
              onPosition: (id, position) {
                setState(() => _mousePositions[id] = position);
              },
            )),
          // Always-available small toggle (even with the keys hidden).
          Positioned(
              top: 6,
              left: 6,
              child: Material(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _sending
                        ? null
                        : () {
                            _finishSwitch();
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
                            ? widget.translate('Finish editing keys')
                            : widget.translate('Toggle virtual keys'),
                        button: true,
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _edit
                                  ? Icons.check
                                  : (_visible
                                      ? Icons.keyboard
                                      : Icons.keyboard_outlined),
                              color: Colors.white,
                              size: 21,
                            ))),
                  ))),
          if (_edit && !_sending)
            Positioned(
                top: 6,
                left: 60,
                child: Material(
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                        tooltip: widget.translate('Add key'),
                        icon: const Icon(Icons.add),
                        onPressed: _spots.length < 40
                            ? () => _editShortcut(null)
                            : null))),
          if (_sending)
            Positioned(
                top: 6,
                left: 60,
                child: ElevatedButton.icon(
                    onPressed: () => setState(() => _cancelled = true),
                    icon: const Icon(Icons.stop),
                    label: Text(widget
                        .translate(_cancelled ? 'Stopping…' : 'Stop macro')))),
          if (_switcher?.active == true)
            Positioned(
                top: 6,
                right: 6,
                child: ElevatedButton.icon(
                    onPressed: _finishSwitch,
                    icon: const Icon(Icons.check),
                    label: Text(widget.translate('Enter')))),
          if (_visible && !_edit)
            Positioned(
                left: 12,
                bottom: bounds.maxHeight * .10,
                child: Row(
                    children: ['Ctrl', 'Opt', 'Cmd']
                        .map((name) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Semantics(
                                button: true,
                                selected: _modifiers.contains(name),
                                child: InkWell(
                                    onTap: () => setState(() {
                                          if (!_modifiers.remove(name)) {
                                            _modifiers.add(name);
                                          }
                                        }),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                        width: 56,
                                        height: 56,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _modifiers.contains(name)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                : Colors.black.withOpacity(.50),
                                            border: Border.all(
                                                color: Colors.white54)),
                                        child: Text(
                                            name == 'Cmd' && !widget.isMac
                                                ? 'Super'
                                                : name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16)))))))
                        .toList())),
          if (_edit && !_sending)
            Positioned(
                top: 6,
                left: 116,
                child: IconButton(
                    tooltip: widget.translate('Reset'),
                    icon: const Icon(Icons.restore),
                    onPressed: () {
                      setState(() { _spots = _defaults(); _mousePositions.clear(); });
                      _save();
                    })),
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
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.black.withOpacity(spot.config.opacity),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(widget.translate(spot.config.title),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }),
        ]);
      });
}
