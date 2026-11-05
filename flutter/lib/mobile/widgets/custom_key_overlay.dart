import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'remote_shortcut.dart';
import 'virtual_key_editor.dart';
import 'virtual_mouse_controls.dart';
import 'virtual_right_mouse_button.dart';

part 'custom_key_storage.dart';

class _KeySpot {
  _KeySpot(this.config, this.x, this.y, {this.rightSlot, this.columnSlot});
  int? rightSlot, columnSlot;
  VirtualKeyConfig config;
  double x, y; // normalized coordinates, 0..1

  Map<String, dynamic> toJson() => {...config.toJson(), 'x': x, 'y': y, if (rightSlot != null) 'rightSlot': rightSlot, if (columnSlot != null) 'columnSlot': columnSlot};

  factory _KeySpot.fromJson(Map<String, dynamic> j) => _KeySpot(
    VirtualKeyConfig.fromJson(j),
    (j['x'] as num?)?.toDouble() ?? .5,
    (j['y'] as num?)?.toDouble() ?? .5,
    rightSlot: j['rightSlot'] as int?,
    columnSlot: j['columnSlot'] as int?,
  );
}

/// Place outside the remote pointer/gesture listeners so key touches stay local.
/// Keys stay down while touched. Visibility and editing are controlled by Operations.
/// Layout is local to the iPad and persists across sessions.
class CustomKeyOverlay extends StatefulWidget {
  const CustomKeyOverlay({
    super.key,
    required this.send,
    this.active = true,
    this.write,
    this.mouseScroll,
    this.rightClick,
    this.isMac = true,
    this.profileId = 'default',
    this.translate = virtualKeyText,
    this.onVisibilityChanged,
  });
  final Future<void> Function(RemoteShortcut) send;
  final RemoteKeyWriter? write;
  final Future<void> Function(int)? mouseScroll;
  final Future<void> Function()? rightClick;
  final ValueChanged<bool>? onVisibilityChanged;
  final bool active;
  final bool isMac;
  final String profileId;
  final String Function(String) translate;

  @override
  State<CustomKeyOverlay> createState() => CustomKeyOverlayState();
}

class CustomKeyOverlayState extends State<CustomKeyOverlay>
    with WidgetsBindingObserver {
  bool get visible => _visible;
  int _loadGeneration = 0;

  void setVisible(bool value) {
    if (!_loaded) return;
    _cancelled = true;
    _releaseKeys();
    setState(() {
      _visible = value;
      _edit = false;
    });
    widget.onVisibilityChanged?.call(_visible);
    _save();
  }

  void editLayout() {
    if (!_loaded) return;
    _releaseKeys();
    setState(() {
      _visible = true;
      _edit = true;
    });
    widget.onVisibilityChanged?.call(_visible);
  }

  @override
  void didUpdateWidget(covariant CustomKeyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active && oldWidget.active) {
      _cancelled = true;
      _releaseKeys();
    }
    if (oldWidget.isMac != widget.isMac || oldWidget.profileId != widget.profileId) {
      _releaseKeys();
      _spots = _defaults();
      _mousePositions.clear();
      _visible = true;
      _loaded = false;
      _load();
    }
  }

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
      'landesk_native/virtual_keys/${base64Url.encode(utf8.encode(widget.profileId))}_${widget.isMac ? 'mac' : 'linux'}.json';
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
      int? rightSlot,
      int? columnSlot,
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
      rightSlot: rightSlot,
      columnSlot: columnSlot,
    );
    return [
      key('Esc', 'VK_ESCAPE', .0, .0),
      key('T', 'VK_T', .98, .26, columnSlot: 0),
      key('C', 'VK_C', .98, .26, columnSlot: 1),
      key('V', 'VK_V', .98, .26, columnSlot: 2),
      key('Space', 'VK_SPACE', .98, .83, rightSlot: 2),
      key('Enter', 'VK_ENTER', .98, .83, rightSlot: 1),
      key('Back', 'VK_BACK', .98, .83, rightSlot: 0),
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
  void didChangeMetrics() {
    // Rotation, window resizing and the software keyboard must never leave a
    // modifier held at its previous screen position.
    _cancelled = true;
    _releaseKeys();
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
      final bottomRowTop = math.max(0.0, bounds.maxHeight - controlSize) *
          (bounds.maxWidth > bounds.maxHeight ? .83 : .96);
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
          if (_visible && widget.rightClick != null)
            VirtualRightMouseButton(onTap: widget.rightClick!, editing: _edit,
              position: _mousePositions['mouse'],
              onPosition: (position) => setState(() => _mousePositions['mouse'] = position),
              onPositionEnd: _save),
          // Editing retains a Done control; visibility lives in Operations.
          if (_edit) Positioned(
            top: bottomRowTop,
            left: 12,
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .85),
              shape: CircleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
                        widget.onVisibilityChanged?.call(_visible);
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
                        widget.onVisibilityChanged?.call(_visible);
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
                      color: Theme.of(context).colorScheme.onSurface,
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
              left: math.max(0.0, bounds.maxWidth - controlSize) * .035,
              top: bottomRowTop,
              child: Row(
                children: ['Ctrl', 'Opt', 'Cmd'].map((name) {
                  final code = {
                    'Ctrl': 'VK_CONTROL',
                    'Opt': 'VK_MENU',
                    'Cmd': 'Meta',
                  }[name]!;
                  return Padding(
                    padding: EdgeInsets.only(right: name == 'Cmd' ? 0 : 10),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
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
                                : Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: .60),
                            border: Border.all(
                              width: _touches.containsValue(code) ? 2 : 1,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Text(
                            name == 'Cmd' && !widget.isMac ? 'Super' : name,
                            style: TextStyle(
                              color: _touches.containsValue(code)
                                  ? Theme.of(context).colorScheme.onSecondary
                                  : Theme.of(context).colorScheme.onSurface,
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
              final left = spot.rightSlot == null
                  ? spot.x.clamp(0.0, 1.0).toDouble() * width
                  : math.max(0.0, width * .98 - spot.rightSlot! * (size + 10));
              final top = spot.y.clamp(0.0, 1.0).toDouble() * height +
                  (spot.columnSlot ?? 0) * (size + 4);
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  key: ValueKey('virtual-key-$i'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress: (_edit || _sending || widget.write != null)
                      ? null
                      : () => setState(() => _edit = true),
                  onPanUpdate: _edit
                      ? (details) {
                          setState(() {
                            spot.rightSlot = null;
                            spot.columnSlot = null;
                            spot.x =
                                ((left + details.delta.dx) /
                                        math.max(width, 1))
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                            spot.y =
                                ((top + details.delta.dy) /
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
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
                            : Theme.of(context).colorScheme.surface.withValues(
                                alpha: spot.config.opacity,
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width:
                              _touches.containsValue(
                                spot.config.steps.first.key,
                              )
                              ? 2
                              : 1,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        widget.translate(spot.config.title),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              (_edit ||
                                  _touches.containsValue(
                                    spot.config.steps.first.key,
                                  ))
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface,
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
