import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A right click at the current remote pointer, outside canvas gesture handling.
class VirtualRightMouseButton extends StatefulWidget {
  const VirtualRightMouseButton({super.key, required this.onTap,
    required this.editing, this.position, required this.onPosition,
    required this.onPositionEnd});
  final Future<void> Function() onTap;
  final bool editing;
  final Offset? position;
  final ValueChanged<Offset> onPosition;
  final VoidCallback onPositionEnd;

  @override
  State<VirtualRightMouseButton> createState() => _VirtualRightMouseButtonState();
}

class _VirtualRightMouseButtonState extends State<VirtualRightMouseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final size = MediaQuery.sizeOf(context).shortestSide < 600 ? 48.0 : 64.0;
    final width = math.max(1.0, bounds.maxWidth - size);
    final height = math.max(1.0, bounds.maxHeight - size);
    final left = widget.position == null
        ? math.max(0.0, width * .98 - 3 * (size + 10)) : widget.position!.dx * width;
    final top = (widget.position?.dy ?? .83) * height;
    final colors = Theme.of(context).colorScheme;
    final label = Localizations.localeOf(context).languageCode == 'zh' ? '右键' : 'Right';
    return Stack(children: [Positioned(left: left, top: top,
      child: Semantics(label: 'Right mouse button', button: true, excludeSemantics: true,
        child: GestureDetector(
          onPanUpdate: widget.editing ? (event) => widget.onPosition(Offset(
            ((left + event.delta.dx) / width).clamp(0.0, 1.0),
            ((top + event.delta.dy) / height).clamp(0.0, 1.0))) : null,
          onPanEnd: widget.editing ? (_) => widget.onPositionEnd() : null,
          onTapDown: widget.editing ? null : (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.editing ? null : () async {
            try { await widget.onTap(); } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Could not send remote shortcut')));
              }
            }
          },
          child: AnimatedContainer(duration: const Duration(milliseconds: 80),
            width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _pressed ? colors.secondaryContainer : colors.surface.withValues(alpha: .85),
              border: Border.all(color: colors.outline)),
            child: FittedBox(fit: BoxFit.scaleDown, child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.mouse_outlined, size: size * .42, color: colors.onSurface),
              Text(label, style: TextStyle(fontSize: 10, color: colors.onSurface)),
            ]))),
        )),
    )]);
  });
}
