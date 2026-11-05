import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A right click at the current remote pointer, outside canvas gesture handling.
class VirtualRightMouseButton extends StatelessWidget {
  const VirtualRightMouseButton({super.key, required this.onTap,
    required this.editing, this.position, required this.onPosition,
    required this.onPositionEnd});
  final Future<void> Function() onTap;
  final bool editing;
  final Offset? position;
  final ValueChanged<Offset> onPosition;
  final VoidCallback onPositionEnd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final size = MediaQuery.sizeOf(context).shortestSide < 600 ? 48.0 : 64.0;
    final width = math.max(1.0, bounds.maxWidth - size);
    final height = math.max(1.0, bounds.maxHeight - size);
    final left = position == null
        ? math.max(0.0, width * .98 - 3 * (size + 10)) : position!.dx * width;
    final top = (position?.dy ?? .83) * height;
    final colors = Theme.of(context).colorScheme;
    return Stack(children: [Positioned(left: left, top: top,
      child: Semantics(label: 'Right mouse button', button: true,
        child: GestureDetector(
          onPanUpdate: editing ? (event) => onPosition(Offset(
            ((left + event.delta.dx) / width).clamp(0.0, 1.0),
            ((top + event.delta.dy) / height).clamp(0.0, 1.0))) : null,
          onPanEnd: editing ? (_) => onPositionEnd() : null,
          onTap: editing ? null : () async {
            try { await onTap(); } catch (_) {
              if (context.mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('Could not send remote shortcut')));
            }
          },
          child: Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: .85),
              border: Border.all(color: colors.outline)),
            child: Icon(Icons.mouse_outlined, size: size * .65,
              color: colors.onSurface)),
        )),
    )]);
  });
}
