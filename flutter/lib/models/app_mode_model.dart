import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../common.dart' show isWeb;
import 'model.dart';
import 'platform_model.dart';

class AppWindow {
  final int id;
  final String app, title;
  final Rect frame;
  final bool thumbnailAvailable;
  const AppWindow(this.id, this.app, this.title, this.frame,
      {this.thumbnailAvailable = false});

  factory AppWindow.fromJson(Map<String, dynamic> json) {
    final r = json['frame'] as Map<String, dynamic>;
    final frame = Rect.fromLTWH(
        (r['x'] as num).toDouble(),
        (r['y'] as num).toDouble(),
        (r['width'] as num).toDouble(),
        (r['height'] as num).toDouble());
    if (!frame.isFinite || frame.isEmpty) {
      throw const FormatException('Invalid window bounds');
    }
    return AppWindow(json['id'] as int, json['app'] as String,
        json['title'] as String? ?? '', frame,
        thumbnailAvailable: json['thumbnail_available'] == true);
  }
}

/// The same transform drives painting and the existing remote input mapping.
class AppViewport {
  final Rect window;
  final Size viewport;
  const AppViewport(this.window, this.viewport);
  double get scale =>
      math.min(viewport.width / window.width, viewport.height / window.height);
  Offset get offset => Offset(
      (viewport.width - window.width * scale) / 2 - window.left * scale,
      (viewport.height - window.height * scale) / 2 - window.top * scale);
  Rect get visible => Rect.fromLTWH(
      offset.dx + window.left * scale,
      offset.dy + window.top * scale,
      window.width * scale,
      window.height * scale);
}

class AppModeModel extends ChangeNotifier {
  final FFI ffi;
  AppModeModel(this.ffi);
  AppWindow? selected;
  String? error;
  Timer? _timer;
  int _nextId = 0, _pendingId = 0;
  Completer<Map<String, dynamic>>? _pending;
  final _thumbnailRequests = <int, Completer<Map<String, dynamic>>>{};

  bool get supported =>
      !isWeb && ffi.ffiModel.pi.platformAdditions['landesk_app_mode'] == 1;

  Future<Map<String, dynamic>> _request(String op,
      [Map<String, dynamic> args = const {}]) async {
    final previous = _pending;
    if (previous != null) {
      try {
        await previous.future;
      } catch (_) {/* The next explicit action may recover. */}
    }
    if (ffi.closed) throw StateError('Connection closed');
    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;
    _pendingId = ++_nextId;
    final timeout = Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) {
        completer.complete({'error': 'The remote computer did not respond. Try again.'});
      }
    });
    try {
      await bind.sessionAppModeRequest(
          sessionId: ffi.sessionId,
          text: jsonEncode({'request_id': _pendingId, 'op': op, ...args}));
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) completer.complete({'error': e.toString()});
      rethrow;
    } finally {
      timeout.cancel();
      if (identical(_pending, completer)) _pending = null;
    }
  }

  void receive(String data) {
    try {
      final response = jsonDecode(data) as Map<String, dynamic>;
      final thumbnail = _thumbnailRequests.remove(response['request_id']);
      if (thumbnail != null) {
        thumbnail.complete(response);
        return;
      }
      if (response['request_id'] != _pendingId ||
          _pending == null ||
          _pending!.isCompleted) {
        return;
      }
      // Complete normally so a late native error cannot become an unhandled Future error.
      _pending!.complete(response);
    } catch (e) {
      debugPrint('Invalid app mode response: $e');
    }
  }

  Map<String, dynamic> _checked(Map<String, dynamic> response) {
    if (response['error'] != null) {
      throw StateError(response['error'] as String);
    }
    return response;
  }

  Rect? localFrame(AppWindow window) {
    final pi = ffi.ffiModel.pi;
    final index = pi.currentDisplay;
    if (index < 0 || index >= pi.displays.length) return null;
    final display = pi.displays[index];
    final rect = Rect.fromLTWH(
        (window.frame.left - display.x) * display.scale,
        (window.frame.top - display.y) * display.scale,
        window.frame.width * display.scale,
        window.frame.height * display.scale);
    final screen = Rect.fromLTWH(
        0, 0, display.width.toDouble(), display.height.toDouble());
    return screen.contains(rect.topLeft) &&
            rect.right <= screen.right &&
            rect.bottom <= screen.bottom
        ? rect
        : null;
  }

  Future<List<AppWindow>> windows() async {
    final response = _checked(await _request('list'));
    return (response['windows'] as List)
        .map((v) => AppWindow.fromJson(v))
        .where((w) => localFrame(w) != null)
        .toList();
  }

  Future<Uint8List?> thumbnail(AppWindow window) async {
    if (!window.thumbnailAvailable ||
        ffi.closed ||
        _thumbnailRequests.length >= 2) {
      return null;
    }
    final id = ++_nextId;
    final response = Completer<Map<String, dynamic>>();
    _thumbnailRequests[id] = response;
    try {
      await bind.sessionAppModeRequest(
          sessionId: ffi.sessionId,
          text: jsonEncode({
            'request_id': id,
            'op': 'thumbnail',
            'window_id': window.id,
          }));
      final value = await response.future.timeout(const Duration(seconds: 3));
      final encoded = value['thumbnail'];
      if (encoded is String && encoded.length <= 43692) {
        return base64Decode(encoded);
      }
    } catch (e) {
      debugPrint('Could not load window thumbnail: $e');
    } finally {
      _thumbnailRequests.remove(id);
    }
    return null;
  }

  Future<void> focus(AppWindow window,
      {required bool fit, double contentScale = 1.0}) async {
    _timer?.cancel();
    error = null;
    try {
      final size = ffi.canvasModel.size;
      final aspect = fit && size.height > 0
          ? (size.width / size.height).clamp(0.2, 5.0)
          : 0.0;
      final response = _checked(await _request('focus', {
        'window_id': window.id,
        'aspect': aspect,
        'height': fit
            ? (size.height / contentScale.clamp(1.0, 1.5)).clamp(160.0, 2160.0)
            : 0.0,
      }));
      _show(AppWindow.fromJson(response['window']));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_pending != null || selected == null) return;
        try {
          final value = _checked(await _request('current'));
          if (selected != null) _show(AppWindow.fromJson(value['window']));
        } catch (e) {
          error = e.toString();
          _clearView();
          try {
            _checked(await _request('desktop'));
          } catch (restoreError) {
            debugPrint('$restoreError');
          }
          notifyListeners();
        }
      });
    } catch (e) {
      _clearView();
      // A focus action may already have resized the window before geometry validation.
      try {
        _checked(await _request('desktop'));
      } catch (restoreError) {
        debugPrint('$restoreError');
      }
      rethrow;
    }
    notifyListeners();
  }

  void _show(AppWindow window) {
    final frame = localFrame(window);
    if (frame == null) {
      throw StateError(
          'The window moved outside this display. Return to desktop.');
    }
    selected = window;
    ffi.canvasModel.setAppFocus(frame);
  }

  Future<void> desktop() async {
    _clearView();
    notifyListeners();
    _checked(await _request('desktop'));
  }

  void _clearView() {
    _timer?.cancel();
    selected = null;
    ffi.canvasModel.setAppFocus(null);
  }

  void close() {
    _timer?.cancel();
    selected = null;
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete({'error': 'Connection closed'});
    }
    _pending = null;
    for (final request in _thumbnailRequests.values) {
      request.complete({});
    }
    _thumbnailRequests.clear();
    ffi.canvasModel.setAppFocus(null);
  }
}
