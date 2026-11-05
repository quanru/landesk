part of 'model.dart';

class CanvasModel with ChangeNotifier {
  // image offset of canvas
  double _x = 0;
  // image offset of canvas
  double _y = 0;
  // image scale
  double _scale = 1.0;
  bool _locked = false;
  double _devicePixelRatio = 1.0;
  Size _size = Size.zero;
  Size? _mobileViewport;

  void updateMobileViewport(Size size) {
    if (_mobileViewport == size) return;
    _mobileViewport = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parent.target?.closed == false) updateViewStyle();
    });
  }

  // the tabbar over the image
  // double tabBarHeight = 0.0;
  // the window border's width
  // double windowBorderWidth = 0.0;
  // remote id
  String id = '';
  late final SessionID sessionId;
  // scroll offset x percent
  double _scrollX = 0.0;
  // scroll offset y percent
  double _scrollY = 0.0;
  ScrollStyle _scrollStyle = ScrollStyle.scrollauto;
  // edge scroll mode: trigger scrolling when the cursor is close to the edge of the view
  int _edgeScrollEdgeThickness = 100;
  // tracks whether edge scroll should be active, prevents spurious
  // scrolling when the cursor enters the view from outside
  EdgeScrollState _edgeScrollState = EdgeScrollState.inactive;
  // fallback strategy for when Bump Mouse isn't available
  late EdgeScrollFallbackState _edgeScrollFallbackState;
  // to avoid hammering a non-functional Bump Mouse
  bool _bumpMouseIsWorking = true;
  ViewStyle _lastViewStyle = ViewStyle.defaultViewStyle();

  Timer? _timerMobileFocusCanvasCursor;
  Timer? _timerMobileRestoreCanvasOffset;
  Offset? _offsetBeforeMobileSoftKeyboard;
  double? _scaleBeforeMobileSoftKeyboard;

  // `isMobileCanvasChanged` is used to avoid canvas reset when changing the input method
  // after showing the soft keyboard.
  bool isMobileCanvasChanged = false;

  final ScrollController _horizontal = ScrollController();
  final ScrollController _vertical = ScrollController();

  final _imageOverflow = false.obs;

  WeakReference<FFI> parent;

  CanvasModel(this.parent) {
    sessionId = parent.target!.sessionId;
  }

  double get x => _x;
  double get y => _y;
  double get scale => _scale;
  bool get locked => _locked;
  double get devicePixelRatio => _devicePixelRatio;
  Size get size => _size;
  ScrollStyle get scrollStyle => _scrollStyle;
  ViewStyle get viewStyle => _lastViewStyle;
  RxBool get imageOverflow => _imageOverflow;

  void setLocked(bool value) {
    if (_locked == value) return;
    _locked = value;
    notifyListeners();
  }

  _resetScroll() => setScrollPercent(0.0, 0.0);

  void setScrollPercent(double x, double y) {
    _scrollX = x.isFinite ? x : 0.0;
    _scrollY = y.isFinite ? y : 0.0;
  }

  void pushScrollPositionToUI(double scrollPixelX, double scrollPixelY) {
    if (_horizontal.hasClients) {
      _horizontal.jumpTo(scrollPixelX);
    }
    if (_vertical.hasClients) {
      _vertical.jumpTo(scrollPixelY);
    }
  }

  ScrollController get scrollHorizontal => _horizontal;
  ScrollController get scrollVertical => _vertical;
  double get scrollX => _scrollX;
  double get scrollY => _scrollY;

  static double get leftToEdge =>
      isDesktop ? windowBorderWidth + kDragToResizeAreaPadding.left : 0;
  static double get rightToEdge =>
      isDesktop ? windowBorderWidth + kDragToResizeAreaPadding.right : 0;
  static double get topToEdge => isDesktop
      ? tabBarHeight + windowBorderWidth + kDragToResizeAreaPadding.top
      : 0;
  static double get bottomToEdge =>
      isDesktop ? windowBorderWidth + kDragToResizeAreaPadding.bottom : 0;

  // mobile only
  double getAdjustY() {
    final bottom =
        parent.target?.cursorModel.keyHelpToolsRectToAdjustCanvas?.bottom ?? 0;
    return max(bottom - MediaQueryData.fromView(ui.window).padding.top, 0);
  }

  updateSize() => _size = getSize();

  updateViewStyle({refreshMousePos = true, notify = true}) async {
    final style = await bind.sessionGetViewStyle(sessionId: sessionId);
    if (style == null) {
      return;
    }

    updateSize();
    final displayWidth = getDisplayWidth();
    final displayHeight = getDisplayHeight();
    final viewStyle = ViewStyle(
      style: style,
      width: size.width,
      height: size.height,
      displayWidth: displayWidth,
      displayHeight: displayHeight,
    );
    // If only the Custom scale percent changed, proceed to update even if
    // the basic ViewStyle fields are equal.
    // In Custom scale mode, the scale percent can change independently of the other
    // ViewStyle fields and is not captured by the equality check. Therefore, we must
    // allow updates to proceed when style == kRemoteViewStyleCustom, even if the
    // rest of the ViewStyle fields are unchanged.
    if (_lastViewStyle == viewStyle &&
        _devicePixelRatio == ui.window.devicePixelRatio &&
        style != kRemoteViewStyleCustom) {
      return;
    }
    if (_lastViewStyle.style != viewStyle.style) {
      _resetScroll();
    }
    _lastViewStyle = viewStyle;
    _scale = viewStyle.scale;

    // Apply custom scale percent when in Custom mode
    if (style == kRemoteViewStyleCustom) {
      try {
        _scale = await getSessionCustomScale(sessionId);
      } catch (e, stack) {
        debugPrint('Error in getSessionCustomScale: $e');
        debugPrintStack(stackTrace: stack);
        _scale = 1.0;
      }
    }

    _devicePixelRatio = ui.window.devicePixelRatio;
    if (kIgnoreDpi) {
      if (style == kRemoteViewStyleOriginal) {
        _scale = 1.0 / _devicePixelRatio;
      } else if (_scale != 0 && style == kRemoteViewStyleCustom) {
        _scale /= _devicePixelRatio;
      }
    }
    _resetCanvasOffset(displayWidth, displayHeight);
    final overflow = _x < 0 || y < 0;
    if (_imageOverflow.value != overflow) {
      _imageOverflow.value = overflow;
    }
    if (notify) {
      notifyListeners();
    }
    if (!isMobile && refreshMousePos) {
      parent.target?.inputModel.refreshMousePos();
    }
    tryUpdateScrollStyle(Duration.zero, style);
  }

  _resetCanvasOffset(int displayWidth, int displayHeight) {
    _x = (size.width - displayWidth * _scale) / 2;
    _y = (size.height - displayHeight * _scale) / 2;
    if (isMobile) {
      _moveToCenterCursor();
    }
  }

  tryUpdateScrollStyle(Duration duration, String? style) async {
    if (_scrollStyle == ScrollStyle.scrollauto) return;
    style ??= await bind.sessionGetViewStyle(sessionId: sessionId);
    if (style != kRemoteViewStyleOriginal && style != kRemoteViewStyleCustom) {
      return;
    }

    _resetScroll();

    Future.delayed(duration, () async {
      // Layout updates scroll extents and detaches scrollbars no longer needed.
      await SchedulerBinding.instance.endOfFrame;
      updateScrollPercent();
    });
  }

  Future<void> updateScrollStyle() async {
    final style = await bind.sessionGetScrollStyle(sessionId: sessionId);

    _scrollStyle =
        style != null ? ScrollStyle.fromString(style) : ScrollStyle.scrollauto;

    if (_scrollStyle != ScrollStyle.scrollauto) {
      // Scrollbar and Scroll Edge share controllers and retain their positions.
      updateScrollPercent();
    }

    notifyListeners();
  }

  Future<void> initializeEdgeScrollEdgeThickness() async {
    final savedValue =
        await bind.sessionGetEdgeScrollEdgeThickness(sessionId: sessionId);

    if (savedValue != null) {
      _edgeScrollEdgeThickness = savedValue;
    }
  }

  void updateEdgeScrollEdgeThickness(int newThickness) {
    _edgeScrollEdgeThickness = newThickness;
    notifyListeners();
  }

  void update(double x, double y, double scale) {
    _x = x;
    _y = y;
    _scale = scale;
    notifyListeners();
  }

  bool get cursorEmbedded =>
      parent.target?.ffiModel._pi.cursorEmbedded ?? false;

  int getDisplayWidth() {
    final defaultWidth = (isDesktop || isWebDesktop)
        ? kDesktopDefaultDisplayWidth
        : kMobileDefaultDisplayWidth;
    return parent.target?.ffiModel.rect?.width.toInt() ?? defaultWidth;
  }

  int getDisplayHeight() {
    final defaultHeight = (isDesktop || isWebDesktop)
        ? kDesktopDefaultDisplayHeight
        : kMobileDefaultDisplayHeight;
    return parent.target?.ffiModel.rect?.height.toInt() ?? defaultHeight;
  }

  static double get windowBorderWidth => stateGlobal.windowBorderWidth.value;
  static double get tabBarHeight => stateGlobal.tabBarHeight;

  void activateLocalCursor() {
    if (isDesktop || isWebDesktop) {
      try {
        RemoteCursorMovedState.find(id).value = false;
      } catch (e) {
        //
      }
    }
  }

  void updateLocalCursor(double x, double y) {
    if (parent.target?.ffiModel.viewOnly == true) return;
    // If keyboard is not permitted, do not move cursor when mouse is moving.
    if (parent.target != null && parent.target!.ffiModel.keyboard) {
      // Draw cursor if is not desktop.
      if (!(isDesktop || isWebDesktop)) {
        parent.target!.cursorModel.moveLocal(x, y);
      } else {
        try {
          RemoteCursorMovedState.find(id).value = false;
        } catch (e) {
          //
        }
      }
    }
  }

  void moveDesktopMouse(double x, double y) {
    if (size.width == 0 || size.height == 0) {
      return;
    }

    // On mobile platforms, move the canvas with the cursor.
    final dw = getDisplayWidth() * _scale;
    final dh = getDisplayHeight() * _scale;
    var dxOffset = 0;
    var dyOffset = 0;
    try {
      if (dw > size.width) {
        dxOffset = (x - dw * (x / size.width) - _x).toInt();
      }
      if (dh > size.height) {
        dyOffset = (y - dh * (y / size.height) - _y).toInt();
      }
    } catch (e) {
      debugPrintStack(
          label:
              '(x,y) ($x,$y), (_x,_y) ($_x,$_y), _scale $_scale, display size (${getDisplayWidth()},${getDisplayHeight()}), size $size, , $e');
      return;
    }

    _x += dxOffset;
    _y += dyOffset;
    if (dxOffset != 0 || dyOffset != 0) {
      notifyListeners();
    }
  }

  void initializeEdgeScrollFallback(TickerProvider tickerProvider) {
    _edgeScrollFallbackState = EdgeScrollFallbackState(this, tickerProvider);
  }

  void disableEdgeScroll() {
    _edgeScrollState = EdgeScrollState.inactive;
    cancelEdgeScroll();
  }

  void rearmEdgeScroll() {
    _edgeScrollState = EdgeScrollState.armed;
  }

  void cancelEdgeScroll() {
    _edgeScrollFallbackState.stop();
  }

  (Vector2, Vector2) getScrollInfo() {
    final scrollPixel = Vector2(
        _horizontal.hasClients ? _horizontal.position.pixels : 0,
        _vertical.hasClients ? _vertical.position.pixels : 0);

    final max = Vector2(
        _horizontal.hasClients ? _horizontal.position.maxScrollExtent : 0,
        _vertical.hasClients ? _vertical.position.maxScrollExtent : 0);

    return (scrollPixel, max);
  }

  void edgeScrollMouse(double x, double y) async {
    if ((_edgeScrollState == EdgeScrollState.inactive) ||
        (size.width == 0 || size.height == 0) ||
        !(_horizontal.hasClients || _vertical.hasClients)) {
      return;
    }

    if (_edgeScrollState == EdgeScrollState.armed) {
      // Edge scroll is armed to become active once the cursor
      // is observed within the rectangle interior to the
      // edge scroll regions. If the user has just moved the
      // cursor in from outside of the window, edge scrolling
      // doesn't happen yet.
      final clientArea = Rect.fromLTWH(0, 0, size.width, size.height);

      final innerZone = clientArea.deflate(_edgeScrollEdgeThickness.toDouble());

      if (innerZone.contains(Offset(x, y))) {
        _edgeScrollState = EdgeScrollState.active;
      } else {
        // Not yet.
        return;
      }
    }

    var dxOffset = 0.0;
    var dyOffset = 0.0;

    if (x < _edgeScrollEdgeThickness) {
      dxOffset = x - _edgeScrollEdgeThickness;
    } else if (x >= size.width - _edgeScrollEdgeThickness) {
      dxOffset = x - (size.width - _edgeScrollEdgeThickness);
    }

    if (y < _edgeScrollEdgeThickness) {
      dyOffset = y - _edgeScrollEdgeThickness;
    } else if (y >= size.height - _edgeScrollEdgeThickness) {
      dyOffset = y - (size.height - _edgeScrollEdgeThickness);
    }

    var encroachment = Vector2(dxOffset, dyOffset);

    var (scrollPixel, max) = getScrollInfo();

    encroachment.clamp(-scrollPixel, max - scrollPixel);

    if (encroachment.length2 == 0) {
      _edgeScrollFallbackState.stop();
    } else {
      var bumpAmount = -encroachment;

      // Round away from 0: this ensures that the mouse will be bumped clear of
      // whichever edge scroll zone(s) it is in
      bumpAmount.x += bumpAmount.x.sign * 0.5;
      bumpAmount.y += bumpAmount.y.sign * 0.5;

      var bumpMouseSucceeded = _bumpMouseIsWorking &&
          (await rustDeskWinManager.call(WindowType.Main, kWindowBumpMouse,
                  {"dx": bumpAmount.x.round(), "dy": bumpAmount.y.round()}))
              .result;

      if (bumpMouseSucceeded) {
        performEdgeScroll(encroachment);
      } else {
        // If we can't BumpMouse, then we switch to slower scrolling with autorepeat

        // Don't keep hammering BumpMouse if it's not working.
        _bumpMouseIsWorking = false;

        // Keep scrolling as long as the user is overtop of an edge.
        _edgeScrollFallbackState.setEncroachment(encroachment);
        _edgeScrollFallbackState.start();
      }
    }
  }

  void performEdgeScroll(Vector2 delta) {
    var (scrollPixel, max) = getScrollInfo();

    scrollPixel += delta;

    scrollPixel.clamp(Vector2.zero(), max);

    var scrollPixelPercent = scrollPixel.clone();

    scrollPixelPercent.divide(max);
    scrollPixelPercent.scale(100.0);

    setScrollPercent(scrollPixelPercent.x, scrollPixelPercent.y);
    pushScrollPositionToUI(scrollPixel.x, scrollPixel.y);

    notifyListeners();
  }

  panX(double dx) {
    _x += dx;
    if (isMobile) {
      isMobileCanvasChanged = true;
    }
    notifyListeners();
  }

  resetOffset() {
    if (isWebDesktop) {
      updateViewStyle();
    } else {
      _resetCanvasOffset(getDisplayWidth(), getDisplayHeight());
    }
    notifyListeners();
  }

  panY(double dy) {
    _y += dy;
    if (isMobile) {
      isMobileCanvasChanged = true;
    }
    notifyListeners();
  }

  // mobile only
  updateScale(double v, Offset focalPoint) {
    if (parent.target?.imageModel.image == null) return;
    final s = _scale;
    _scale *= v;
    final maxs = parent.target?.imageModel.maxScale ?? 1;
    final mins = parent.target?.imageModel.minScale ?? 1;
    if (_scale > maxs) _scale = maxs;
    if (_scale < mins) _scale = mins;
    // (focalPoint.dx - _x_1) / s1 + displayOriginX = (focalPoint.dx - _x_2) / s2 + displayOriginX
    // _x_2 = focalPoint.dx - (focalPoint.dx - _x_1) / s1 * s2
    _x = focalPoint.dx - (focalPoint.dx - _x) / s * _scale;
    final adjust = getAdjustY();
    // (focalPoint.dy - _y_1 - adjust) / s1 + displayOriginY = (focalPoint.dy - _y_2 - adjust) / s2 + displayOriginY
    // _y_2 = focalPoint.dy - adjust - (focalPoint.dy - _y_1 - adjust) / s1 * s2
    _y = focalPoint.dy - adjust - (focalPoint.dy - _y - adjust) / s * _scale;
    if (isMobile) {
      isMobileCanvasChanged = true;
    }
    notifyListeners();
  }

  // For reset canvas to the last view style
  reset() {
    _scale = _lastViewStyle.scale;
    _devicePixelRatio = ui.window.devicePixelRatio;
    if (kIgnoreDpi && _lastViewStyle.style == kRemoteViewStyleOriginal) {
      _scale = 1.0 / _devicePixelRatio;
    }
    _resetCanvasOffset(getDisplayWidth(), getDisplayHeight());
    bind.sessionSetViewStyle(sessionId: sessionId, value: _lastViewStyle.style);
    notifyListeners();
  }

  clear() {
    _x = 0;
    _y = 0;
    _scale = 1.0;
    _locked = false;
    _lastViewStyle = ViewStyle.defaultViewStyle();
    _timerMobileFocusCanvasCursor?.cancel();
    _timerMobileRestoreCanvasOffset?.cancel();
    _offsetBeforeMobileSoftKeyboard = null;
    _scaleBeforeMobileSoftKeyboard = null;
  }

  updateScrollPercent() {
    final percentX = _horizontal.hasClients
        ? _horizontal.position.extentBefore /
            (_horizontal.position.extentBefore +
                _horizontal.position.extentInside +
                _horizontal.position.extentAfter)
        : 0.0;
    final percentY = _vertical.hasClients
        ? _vertical.position.extentBefore /
            (_vertical.position.extentBefore +
                _vertical.position.extentInside +
                _vertical.position.extentAfter)
        : 0.0;
    setScrollPercent(percentX, percentY);
  }

  void mobileFocusCanvasCursor() {
    _timerMobileFocusCanvasCursor?.cancel();
    _timerMobileFocusCanvasCursor =
        Timer(Duration(milliseconds: 100), () async {
      updateSize();
      _resetCanvasOffset(getDisplayWidth(), getDisplayHeight());
      notifyListeners();
    });
  }

  void saveMobileOffsetBeforeSoftKeyboard() {
    _timerMobileRestoreCanvasOffset?.cancel();
    _offsetBeforeMobileSoftKeyboard = Offset(_x, _y);
    _scaleBeforeMobileSoftKeyboard = _scale;
  }

  void restoreMobileOffsetAfterSoftKeyboard() {
    _timerMobileRestoreCanvasOffset?.cancel();
    _timerMobileFocusCanvasCursor?.cancel();
    final targetOffset = _offsetBeforeMobileSoftKeyboard;
    final targetScale = _scaleBeforeMobileSoftKeyboard;
    if (targetOffset == null || targetScale == null) {
      return;
    }
    _timerMobileRestoreCanvasOffset = Timer(Duration(milliseconds: 100), () {
      updateSize();
      _x = targetOffset.dx;
      _y = targetOffset.dy;
      _scale = targetScale;
      _offsetBeforeMobileSoftKeyboard = null;
      _scaleBeforeMobileSoftKeyboard = null;
      notifyListeners();
    });
  }

  // mobile only
  // Move the canvas to make the cursor visible(center) on the screen.
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

// data for cursor
