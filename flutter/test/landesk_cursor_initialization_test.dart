import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/common.dart' as common;
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Input extends Fake implements InputModel {
  final moves = <Offset>[];

  @override
  Future<void> moveMouse(double x, double y) async => moves.add(Offset(x, y));
}

class _Canvas extends Fake implements CanvasModel {
  @override
  void resetOffset() {}
}

class _Peer extends Fake implements FfiModel {
  @override
  final pi = PeerInfo()..platform = kPeerPlatformMacOS;

  @override
  Rect get rect => const Rect.fromLTWH(0, 0, 1920, 1080);
}

class _Session extends Fake implements FFI {
  @override
  final sessionId = common.SessionID('11111111-1111-4111-8111-111111111111');
  @override
  final ffiModel = _Peer();
  @override
  final _Input inputModel = _Input();
  @override
  final canvasModel = _Canvas();
  @override
  late final cursorModel = CursorModel(WeakReference<FFI>(this));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opening or reinitializing a Mac stream preserves the remote pointer',
      () async {
    final wasMobile = common.isMobile;
    common.isMobile = true;
    addTearDown(() => common.isMobile = wasMobile);
    final ffi = _Session();
    addTearDown(ffi.cursorModel.dispose);
    await ffi.cursorModel.updateCursorPosition({'x': '480', 'y': '270'}, 'mac');
    await initializeCursorAndCanvas(ffi);
    await initializeCursorAndCanvas(ffi);
    expect(ffi.inputModel.moves, isEmpty);
    expect(ffi.cursorModel.offset, const Offset(480, 270));
  });
}
