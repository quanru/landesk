import 'package:flutter/gestures.dart';

/// Reserves the second tap for either a double click or a one-finger zoom.
class QuickZoomGestureRecognizer extends OneSequenceGestureRecognizer {
  void Function(Offset position)? onDoubleTap;
  void Function(double dy, Offset anchor)? onZoom;
  Duration? _lastUp;
  Offset? _lastPosition;
  int? _pointer;
  Offset _origin = Offset.zero;
  bool _second = false;
  bool _moved = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch || _pointer != null) {
      _lastUp = null;
      if (_pointer != null) {
        stopTrackingPointer(_pointer!);
        _pointer = null;
        _second = false;
      }
      resolve(GestureDisposition.rejected);
      return;
    }
    startTrackingPointer(event.pointer, event.transform);
    _pointer = event.pointer;
    _origin = event.position;
    _moved = false;
    final elapsed = _lastUp == null ? null : event.timeStamp - _lastUp!;
    _second =
        elapsed != null &&
        elapsed >= kDoubleTapMinTime &&
        elapsed <= kDoubleTapTimeout &&
        (event.position - _lastPosition!).distance <= kDoubleTapSlop;
    _lastUp = null;
    if (_second) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      final wasMoved = _moved;
      _moved |= (event.position - _origin).distance > kTouchSlop;
      if (_second && _moved) {
        onZoom?.call(
          wasMoved ? event.delta.dy : event.position.dy - _origin.dy,
          _origin,
        );
      } else if (_moved) {
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (event is PointerUpEvent && !_moved) {
        if (_second) {
          onDoubleTap?.call(_origin);
        } else {
          _lastUp = event.timeStamp;
          _lastPosition = _origin;
        }
      }
      if (!_second) resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      _pointer = null;
      _second = false;
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (_pointer == pointer) {
      stopTrackingPointer(pointer);
      _pointer = null;
      _second = false;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}
  @override
  String get debugDescription => 'quick zoom';
}
