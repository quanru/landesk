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

  Map<String, dynamic> toJson() => {...config.toJson(), 'x': x, 'y': y};

  factory _KeySpot.fromJson(Map<String, dynamic> j) => _KeySpot(
    VirtualKeyConfig.fromJson(j),
    (j['x'] as num?)?.toDouble() ?? .5,
    (j['y'] as num?)?.toDouble() ?? .5,
  );
}

/// Place outside the remote pointer/gesture listeners so key touches stay local.
/// Keys stay down while touched. Long press the toggle to edit the layout.
/// Layout is local to the iPad and persists across sessions.
class CustomKeyOverlay extends StatefulWidget {
  const CustomKeyOverlay({
    super.key,
    required this.send,
    this.write,
    this.mouseScroll,
    this.isMac = true,
    this.profileId = 'default',
    this.translate = virtualKeyText,
  });
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
  RemoteHeldKeys? _heldKeys;
  final Map<int, String> _touches = {};

  Future<void> _releaseKeys() async {
    _touches.clear();
    await _heldKeys?.releaseAll();
    if (mounted) setState(() {});
  }

  void _pressKey(int pointer, RemoteShortcut key) {
    if (_edit || _sending || _heldKeys == null) return;
    setState(() => _touches[pointer] = key.key);
    _heldKeys!.press(pointer, key);
  }

  void _releaseKey(int pointer) {
    if (_touches.containsKey(pointer)) {
      setState(() => _touches.remove(pointer));
    }
    // An earlier bridge error may clear visual state while this pointer's down
    // is still queued. Always enqueue its up to avoid leaving that key held.
    _heldKeys?.release(pointer);
  }

  String get _filename =>
      'virtual_keys_v3/${base64Url.encode(utf8.encode(widget.profileId))}_${widget.isMac ? 'mac' : 'linux'}.json';
  final Map<String, Offset> _mousePositions = {};
  bool _sending = false;
  bool _sendingMacro = false;
  bool _loaded = false;
  Future<void> _pendingSave = Future.value();
  late List<_KeySpot> _spots = _defaults();
  bool _edit = false;
  bool _visible = true;

  List<_KeySpot> _defaults() {
    _KeySpot key(
      String title,
      String code,
      double x,
      double y, {
      bool command = false,
      bool ctrl = false,
      bool alt = false,
    }) => _KeySpot(
      VirtualKeyConfig(
        title,
        [RemoteShortcut(title, code, command: command, ctrl: ctrl, alt: alt)],
        size: 64,
        opacity: .60,
      ),
      x,
      y,
    );
    return [
      key('Esc', 'VK_ESCAPE', .02, .02),
      key('Tab', 'VK_TAB', .98, .25),
      key('C', 'VK_C', .98, .39),
      key('V', 'VK_V', .98, .53),
      key('↑', 'VK_UP', .10, .40),
      key('↓', 'VK_DOWN', .10, .54),
      key('Enter', 'VK_ENTER', .90, .85),
      key('Space', 'VK_SPACE', .82, .85),
      key('Back', 'VK_BACK', .98, .85),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.write != null) {
      _heldKeys = RemoteHeldKeys(
        widget.write!,
        onError: (error) {
          debugPrint('Remote held key failed: $error');
          if (mounted) {
            setState(() => _touches.clear());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.translate('Could not send remote shortcut'),
                ),
              ),
            );
          }
        },
      );
    }
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _cancelled = true;
      _releaseKeys();
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    _releaseKeys();
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
          '${(await getApplicationSupportDirectory()).path}/rustdesk_mobile_virtual_keys_v2_${widget.isMac ? 'mac' : 'linux'}.json',
        );
      }
      if (!await file.exists()) return;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rows = (data['spots'] as List).cast<Map<String, dynamic>>();
      if (!mounted || rows.length > 40) return;
      setState(() {
        _spots = rows.map(_KeySpot.fromJson).toList();
        // Retire the old built-in chords while retaining user-created macros,
        // key sizes and positions. The new defaults use physical-key semantics.
        _spots.removeWhere(
          (spot) =>
              spot.config.steps.length == 1 &&
              ((['⌘ Tab', 'Alt Tab'].contains(spot.config.title) &&
                      spot.config.steps.first.key == 'VK_TAB') ||
                  (['⌘ Space', 'Super Space'].contains(spot.config.title) &&
                      spot.config.steps.first.key == 'VK_SPACE')),
        );
        for (final spot in _spots) {
          final config = spot.config;
          if (config.steps.length != 1) continue;
          final code = config.steps.first.key;
          final title = (code == 'VK_C' && ['Copy', 'C'].contains(config.title))
              ? 'C'
              : (code == 'VK_V' && ['Paste', 'V'].contains(config.title))
              ? 'V'
              : (code == 'VK_TAB' && config.title == 'T')
              ? 'Tab'
              : null;
          if (title != null) {
            spot.config = VirtualKeyConfig(
              title,
              [RemoteShortcut(title, code)],
              size: config.size,
              opacity: config.opacity,
              delayMs: config.delayMs,
            );
          }
        }
        _visible = data['visible'] != false;
        final positions = data['mousePositions'];
        if (positions is Map) {
          for (final id in ['mouse', 'wheel']) {
            final p = positions[id];
            if (p is List &&
                p.length == 2 &&
                p.every((v) => v is num && v.isFinite)) {
              _mousePositions[id] = Offset(
                (p[0] as num).toDouble().clamp(0, 1),
                (p[1] as num).toDouble().clamp(0, 1),
              );
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
      'mousePositions': _mousePositions.map(
        (id, p) => MapEntry(id, [p.dx, p.dy]),
      ),
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
            SnackBar(
              content: Text(widget.translate('Could not save key layout')),
            ),
          );
        }
      }
    });
    return _pendingSave;
  }

  Future<void> _send(VirtualKeyConfig config) async {
    if (_sending || _touches.isNotEmpty) return;
    _cancelled = false;
    setState(() {
      _sending = true;
      _sendingMacro = config.steps.length > 1;
    });
    try {
      await _releaseKeys();
      await sendRemoteMacro(
        config.steps,
        config.delayMs,
        widget.send,
        cancelled: () => !mounted || _cancelled,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.translate('Could not send remote shortcut')),
          ),
        );
      }
      debugPrint('Remote shortcut failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editShortcut(int? index) async {
    await _releaseKeys();
    final result = await showDialog<VirtualKeyEditResult>(
      context: context,
      builder: (_) => VirtualKeyEditor(
        initial: index == null
            ? VirtualKeyConfig('Key', [
                const RemoteShortcut('Key', 'VK_ESCAPE'),
              ])
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (!_loaded) return const SizedBox.expand();
      final controlSize = MediaQuery.sizeOf(context).shortestSide < 600
          ? 48.0
          : 64.0;
      final bottomRowTop = math.max(0.0, bounds.maxHeight - controlSize) * .85;
      return Stack(
        children: [
          if (_visible && widget.mouseScroll != null)
            Positioned.fill(
              child: VirtualMouseControls(
                scroll: widget.mouseScroll!,
                translate: widget.translate,
                editing: _edit,
                positions: _mousePositions,
                onPositionEnd: _save,
                onPosition: (id, position) {
                  setState(() => _mousePositions[id] = position);
                },
              ),
            ),
          // Always available, including when the keys are hidden.
          Positioned(
            top: bottomRowTop,
            left: 12,
            child: Material(
              color: const Color(0xFF484848).withValues(alpha: .60),
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white54),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending
                    ? null
                    : () {
                        _releaseKeys();
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
                    : () {
                        _releaseKeys();
                        setState(() {
                          _visible = true;
                          _edit = !_edit;
                        });
                      },
                child: Semantics(
                  label: _edit
                      ? widget.translate('Finish editing keys')
                      : widget.translate('Toggle virtual keys'),
                  button: true,
                  child: SizedBox(
                    width: controlSize,
                    height: controlSize,
                    child: Icon(
                      _edit
                          ? Icons.check
                          : (_visible
                                ? Icons.keyboard
                                : Icons.keyboard_outlined),
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                      : null,
                ),
              ),
            ),
          if (_sending && _sendingMacro)
            Positioned(
              top: 6,
              left: 60,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _cancelled = true),
                icon: const Icon(Icons.stop),
                label: Text(
                  widget.translate(_cancelled ? 'Stopping…' : 'Stop macro'),
                ),
              ),
            ),
          if (_visible && !_edit)
            Positioned(
              left: 12 + controlSize + 10,
              top: bottomRowTop,
              child: Row(
                children: ['Ctrl', 'Opt', 'Cmd'].map((name) {
                  final code = {
                    'Ctrl': 'VK_CONTROL',
                    'Opt': 'VK_MENU',
                    'Cmd': 'Meta',
                  }[name]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Semantics(
                      button: true,
                      selected: _touches.containsValue(code),
                      child: Listener(
                        onPointerDown: (event) => _pressKey(
                          event.pointer,
                          RemoteShortcut(name, code),
                        ),
                        onPointerUp: (event) => _releaseKey(event.pointer),
                        onPointerCancel: (event) => _releaseKey(event.pointer),
                        child: Container(
                          width: MediaQuery.sizeOf(context).shortestSide < 600
                              ? 48
                              : 64,
                          height: MediaQuery.sizeOf(context).shortestSide < 600
                              ? 48
                              : 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _touches.containsValue(code)
                                ? Theme.of(context).colorScheme.secondary
                                : const Color(
                                    0xFF484848,
                                  ).withValues(alpha: .60),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: Text(
                            name == 'Cmd' && !widget.isMac ? 'Super' : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_edit && !_sending)
            Positioned(
              top: 6,
              left: 116,
              child: IconButton(
                tooltip: widget.translate('Reset'),
                icon: const Icon(Icons.restore),
                onPressed: () {
                  setState(() {
                    _spots = _defaults();
                    _mousePositions.clear();
                  });
                  _save();
                },
              ),
            ),
          if (_visible)
            ...List.generate(_spots.length, (i) {
              final spot = _spots[i];
              final phone = MediaQuery.sizeOf(context).shortestSide < 600;
              final displaySize = phone
                  ? math.max(44.0, spot.config.size * .75)
                  : spot.config.size;
              final size = math.min(
                displaySize,
                math.min(bounds.maxWidth, bounds.maxHeight),
              );
              final width = math.max(0.0, bounds.maxWidth - size);
              final height = math.max(0.0, bounds.maxHeight - size);
              return Positioned(
                left: spot.x.clamp(0.0, 1.0).toDouble() * width,
                top: spot.y.clamp(0.0, 1.0).toDouble() * height,
                child: GestureDetector(
                  key: ValueKey('virtual-key-$i'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress: (_edit || _sending || widget.write != null)
                      ? null
                      : () => setState(() => _edit = true),
                  onPanUpdate: _edit
                      ? (details) {
                          setState(() {
                            spot.x =
                                ((spot.x * width + details.delta.dx) /
                                        math.max(width, 1))
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                            spot.y =
                                ((spot.y * height + details.delta.dy) /
                                        math.max(height, 1))
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                          });
                        }
                      : null,
                  onPanEnd: _edit ? (_) => _save() : null,
                  onTap: () {
                    if (_edit) {
                      _editShortcut(i);
                    } else if (widget.write == null ||
                        spot.config.steps.length > 1) {
                      _send(spot.config);
                    }
                  },
                  child: Listener(
                    onPointerDown: (event) {
                      if (spot.config.steps.length == 1) {
                        _pressKey(event.pointer, spot.config.steps.first);
                      }
                    },
                    onPointerUp: (event) => _releaseKey(event.pointer),
                    onPointerCancel: (event) => _releaseKey(event.pointer),
                    child: Container(
                      width: size,
                      height: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            (_edit ||
                                _touches.containsValue(
                                  spot.config.steps.first.key,
                                ))
                            ? Theme.of(context).colorScheme.secondary
                            : const Color(
                                0xFF484848,
                              ).withValues(alpha: spot.config.opacity),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54),
                      ),
                      child: Text(
                        widget.translate(spot.config.title),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: phone ? 13 : 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    },
  );
}
