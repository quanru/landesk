import 'dart:async';
import 'package:flutter/material.dart';

/// Local controls: only their painted bounds intercept remote-canvas touches.
class VirtualMouseControls extends StatefulWidget {
  const VirtualMouseControls({
    super.key,
    required this.button,
    required this.scroll,
    required this.move,
    required this.translate,
    this.editing = false,
    this.positions = const {},
    required this.onPosition,
    required this.onPositionEnd,
  });
  final Future<void> Function(String, bool) button;
  final Future<void> Function(int) scroll;
  final Future<void> Function(Offset) move;
  final String Function(String) translate;
  final bool editing;
  final Map<String, Offset> positions;
  final void Function(String, Offset) onPosition;
  final VoidCallback onPositionEnd;

  @override
  State<VirtualMouseControls> createState() => _VirtualMouseControlsState();
}

class _VirtualMouseControlsState extends State<VirtualMouseControls>
    with WidgetsBindingObserver {
  final Map<int, String> _pointers = {};
  Future<void> _pending = Future.value();
  Timer? _repeat;
  int? _wheelPointer;
  String? _wheelAction;
  double _distance = 0;
  bool _scrollBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _queue(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object error) {
      debugPrint('Virtual mouse input failed: $error');
    });
  }

  void _releaseAll() {
    _stopWheel();
    for (final button in _pointers.values.toSet()) {
      _queue(() => widget.button(button, false));
    }
    _pointers.clear();
  }

  @override
  void didUpdateWidget(VirtualMouseControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing && !oldWidget.editing) _releaseAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _releaseAll();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _releaseAll();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _scroll(int steps) async {
    // Slow transports must not accumulate seconds of scrolling after release.
    if (_scrollBusy || widget.editing) return;
    _scrollBusy = true;
    try {
      await widget.scroll(steps);
    } catch (error) {
      debugPrint('Virtual wheel input failed: $error');
    } finally {
      _scrollBusy = false;
    }
  }

  void _stopWheel() {
    _repeat?.cancel();
    _repeat = null;
    _wheelPointer = null;
    _wheelAction = null;
    _distance = 0;
  }

  Widget _face(
    String label,
    IconData icon,
    bool active,
    Widget Function(Widget) input, {
    Widget? glyph,
    double width = 48,
    double height = 48,
  }) {
    return Semantics(
      label: widget.translate(label),
      button: true,
      selected: active,
      child: input(
        AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.black.withValues(alpha: .55),
            border: Border.all(color: Colors.white54),
            borderRadius: BorderRadius.circular(24),
          ),
          child: glyph ?? Icon(icon, color: Colors.white, size: 25),
        ),
      ),
    );
  }

  Widget _mouse(String button, String label, IconData icon) => _face(
    label,
    icon,
    _pointers.containsValue(button),
    (child) => Listener(
      key: ValueKey('virtual-mouse-$button'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: widget.editing
          ? null
          : (event) {
              if (_pointers.containsValue(button)) return;
              setState(() => _pointers[event.pointer] = button);
              _queue(() => widget.button(button, true));
            },
      onPointerMove: widget.editing
          ? null
          : (event) {
              if (_pointers[event.pointer] == 'left') {
                _queue(() => widget.move(event.delta));
              }
            },
      onPointerUp: (event) => _release(event.pointer),
      onPointerCancel: (event) => _release(event.pointer),
      child: child,
    ),
    glyph: CustomPaint(
      size: const Size(26, 32),
      painter: _MouseGlyph(button == 'right'),
    ),
  );

  void _release(int pointer) {
    final button = _pointers.remove(pointer);
    if (button == null) return;
    _queue(() => widget.button(button, false));
    if (mounted) setState(() {});
  }

  Widget _wheel(String action, String label, IconData icon, int direction) =>
      _face(
        label,
        icon,
        _wheelAction == action,
        (child) => Listener(
          key: ValueKey('virtual-wheel-$action'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.editing
              ? null
              : (event) {
                  if (_wheelPointer != null) return;
                  setState(() {
                    _wheelPointer = event.pointer;
                    _wheelAction = action;
                  });
                  if (direction != 0) {
                    _scroll(direction);
                    _repeat = Timer(const Duration(milliseconds: 350), () {
                      _scroll(direction);
                      _repeat = Timer.periodic(
                        const Duration(milliseconds: 80),
                        (_) => _scroll(direction),
                      );
                    });
                  }
                },
          onPointerMove: widget.editing
              ? null
              : (event) {
                  if (_wheelPointer != event.pointer || direction != 0) return;
                  _distance += event.delta.dy;
                  final steps = (_distance / 12).truncate();
                  if (steps != 0) {
                    _distance -= steps * 12;
                    _scroll(-steps.clamp(-5, 5));
                  }
                },
          onPointerUp: (event) {
            if (_wheelPointer == event.pointer) setState(_stopWheel);
          },
          onPointerCancel: (event) {
            if (_wheelPointer == event.pointer) setState(_stopWheel);
          },
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      Widget place(String id, Offset fallback, Size size, Widget child) {
        final position = widget.positions[id] ?? fallback;
        final width = (bounds.maxWidth - size.width).clamp(
          1.0,
          double.infinity,
        );
        final height = (bounds.maxHeight - size.height).clamp(
          1.0,
          double.infinity,
        );
        return Positioned(
          left: position.dx * width,
          top: position.dy * height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: widget.editing
                ? (event) => widget.onPosition(
                    id,
                    Offset(
                      (position.dx + event.delta.dx / width).clamp(0.0, 1.0),
                      (position.dy + event.delta.dy / height).clamp(0.0, 1.0),
                    ),
                  )
                : null,
            onPanEnd: widget.editing ? (_) => widget.onPositionEnd() : null,
            child: child,
          ),
        );
      }

      return Stack(
        children: [
          place(
            'wheel',
            const Offset(.15, .50),
            const Size(48, 160),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _wheel('up', 'Scroll up', Icons.keyboard_arrow_up, 1),
                const SizedBox(height: 8),
                _wheel('slide', 'Slide to scroll', Icons.drag_handle, 0),
                const SizedBox(height: 8),
                _wheel('down', 'Scroll down', Icons.keyboard_arrow_down, -1),
              ],
            ),
          ),
          place(
            'mouse',
            const Offset(.60, .98),
            const Size(104, 48),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mouse(
                  'left',
                  'Left click; hold and slide to drag',
                  Icons.mouse,
                ),
                const SizedBox(width: 8),
                _mouse('right', 'Right click', Icons.ads_click),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _MouseGlyph extends CustomPainter {
  const _MouseGlyph(this.right);
  final bool right;
  @override
  void paint(Canvas canvas, Size size) {
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(11),
    );
    canvas.save();
    canvas.clipRRect(outline);
    canvas.drawRRect(outline, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(
        right ? size.width / 2 : 0,
        0,
        size.width / 2,
        size.height * .55,
      ),
      Paint()..color = Colors.blueAccent,
    );
    final line = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * .55),
      line,
    );
    canvas.drawLine(
      Offset(0, size.height * .55),
      Offset(size.width, size.height * .55),
      line,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MouseGlyph oldDelegate) => right != oldDelegate.right;
}
