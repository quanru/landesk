part of 'model.dart';

extension _CanvasGeometry on CanvasModel {
  Size getSize() {
    if (isMobile && _mobileViewport != null) {
      final overlay = parent.target?.cursorModel.keyHelpToolsRectToAdjustCanvas;
      return Size(_mobileViewport!.width,
          max(0, _mobileViewport!.height - (overlay?.height ?? 0)));
    }
    final mediaData = MediaQueryData.fromView(ui.window);
    final size = mediaData.size;
    // If minimized, w or h may be negative here.
    double w = size.width - CanvasModel.leftToEdge - CanvasModel.rightToEdge;
    double h = size.height - CanvasModel.topToEdge - CanvasModel.bottomToEdge;
    if (isMobile) {
      // Account for horizontal safe area insets on both orientations.
      w = w - mediaData.padding.left - mediaData.padding.right;
      // Vertically, subtract the bottom keyboard inset (viewInsets.bottom) and any
      // bottom overlay (e.g. key-help tools) so the canvas is not covered.
      h = h -
          mediaData.viewInsets.bottom -
          (parent.target?.cursorModel.keyHelpToolsRectToAdjustCanvas?.bottom ??
              0);
      // Orientation-specific handling:
      //  - Portrait: additionally subtract top padding (e.g. status bar / notch)
      //  - Landscape: does not subtract mediaData.padding.top/bottom (home indicator auto-hides)
      final isPortrait = size.height > size.width;
      if (isPortrait) {
        // In portrait mode, subtract the top safe-area padding (e.g. status bar / notch)
        // so the remote image is not truncated, while keeping the bottom inset to avoid
        // introducing unnecessary blank space around the canvas.
        //
        // iOS -> Android, portrait, adjust mode:
        // h = h (no padding subtracted): top and bottom are truncated
        //   https://github.com/user-attachments/assets/30ed4559-c27e-432b-847f-8fec23c9f998
        // h = h - top - bottom: extra blank spaces appear
        //   https://github.com/user-attachments/assets/12a98817-3b4e-43aa-be0f-4b03cf364b7e
        // h = h - top (current): works fine
        //   https://github.com/user-attachments/assets/95f047f2-7f47-4a36-8113-5023989a0c81
        h = h - mediaData.padding.top;
      }
    }
    return Size(w < 0 ? 0 : w, h < 0 ? 0 : h);
  }

  // Mobile only: keep the cursor visible when the desktop exceeds the viewport.
  void _moveToCenterCursor() {
    Rect? imageRect = parent.target?.ffiModel.rect;
    if (imageRect == null) {
      // unreachable
      return;
    }
    final maxX = 0.0;
    final minX = _size.width + (imageRect.left - imageRect.right) * _scale;
    final maxY = 0.0;
    final minY = _size.height + (imageRect.top - imageRect.bottom) * _scale;
    Offset offsetToCenter =
        parent.target?.cursorModel.getCanvasOffsetToCenterCursor() ??
            Offset.zero;
    if (minX < 0) {
      _x = min(max(offsetToCenter.dx, minX), maxX);
    } else {
      // _size.width > (imageRect.right, imageRect.left) * _scale, we should not change _x
    }
    if (minY < 0) {
      _y = min(max(offsetToCenter.dy, minY), maxY);
    } else {
      // _size.height > (imageRect.bottom - imageRect.top) * _scale, , we should not change _y
    }
  }

}
