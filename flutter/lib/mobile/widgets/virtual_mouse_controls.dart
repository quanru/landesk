import 'package:flutter/material.dart';

/// A single drag-to-scroll wheel. Only its bounds intercept canvas touches.
class VirtualMouseControls extends StatefulWidget {
  const VirtualMouseControls({
    super.key,
    required this.scroll,
    required this.translate,
    this.editing = false,
    this.positions = const {},
    required this.onPosition,
    required this.onPositionEnd,
  });
  final Future<void> Function(int) scroll;
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
  int? _pointer;
  double _distance = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _stop() {
    _pointer = null;
    _distance = 0;
  }

  @override
  void didUpdateWidget(VirtualMouseControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing && !oldWidget.editing) _stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) setState(_stop);
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _scroll(int steps) async {
    // Never queue a scroll tail behind a slow transport.
    if (_busy) return;
    _busy = true;
    try {
      await widget.scroll(steps);
    } catch (error) {
      debugPrint('Virtual wheel input failed: $error');
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      const size = 64.0;
      final position = widget.positions['wheel'] ?? const Offset(.15, .50);
      final width = (bounds.maxWidth - size).clamp(1.0, double.infinity);
      final height = (bounds.maxHeight - size).clamp(1.0, double.infinity);
      return Stack(
        children: [
          Positioned(
            left: position.dx * width,
            top: position.dy * height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: widget.editing
                  ? (event) => widget.onPosition(
                      'wheel',
                      Offset(
                        (position.dx + event.delta.dx / width).clamp(0.0, 1.0),
                        (position.dy + event.delta.dy / height).clamp(0.0, 1.0),
                      ),
                    )
                  : null,
              onPanEnd: widget.editing ? (_) => widget.onPositionEnd() : null,
              onPanCancel: widget.editing ? widget.onPositionEnd : null,
              child: Semantics(
                label: widget.translate('Slide to scroll'),
                button: true,
                selected: _pointer != null,
                child: Listener(
                  key: const ValueKey('virtual-wheel-slide'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: widget.editing
                      ? null
                      : (event) {
                          if (_pointer != null) return;
                          setState(() {
                            _pointer = event.pointer;
                            _distance = 0;
                          });
                        },
                  onPointerMove: widget.editing
                      ? null
                      : (event) {
                          if (_pointer != event.pointer) return;
                          _distance += event.delta.dy;
                          final steps = (_distance / 12).truncate();
                          if (steps != 0) {
                            _distance -= steps * 12;
                            _scroll(-steps.clamp(-5, 5));
                          }
                        },
                  onPointerUp: (event) {
                    if (_pointer == event.pointer) setState(_stop);
                  },
                  onPointerCancel: (event) {
                    if (_pointer == event.pointer) setState(_stop);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pointer != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black.withValues(alpha: .55),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_drop_up,
                          size: 20,
                          color: Colors.white,
                        ),
                        Icon(Icons.drag_handle, size: 20, color: Colors.white),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
