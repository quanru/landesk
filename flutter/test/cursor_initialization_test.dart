import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _Input extends Fake implements InputModel {
  final moves = <Offset>[];

  @override
  Future<void> moveMouse(double x, double y) async {
    moves.add(Offset(x, y));
  }
}

class _Canvas extends Fake implements CanvasModel {
  @override
  void resetOffset() {}
}

class _Session extends Fake implements FFI {
  @override
  final _Input inputModel = _Input();
  @override
  final canvasModel = _Canvas();
  @override
  late final ffiModel = FfiModel(WeakReference(this));
  @override
  late final cursorModel = CursorModel(WeakReference(this));
  @override
  final sessionId = UuidValue('00000000-0000-0000-0000-000000000000');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'first frame and reconnect do not send mouse input or discard position',
    () async {
      final session = _Session();
      session.cursorModel.updateDisplayOriginWithCursor(0, 0, 640, 360);
      await initializeCursorAndCanvas(session);
      await initializeCursorAndCanvas(session);
      expect(session.inputModel.moves, isEmpty);
      expect(session.cursorModel.offset, const Offset(640, 360));
    },
  );

  test(
    'restoring a canvas on an offset display only updates local geometry',
    () {
      final session = _Session();
      session.cursorModel.updateDisplayOriginWithCursor(-1920, 0, -800, 400);
      expect(session.inputModel.moves, isEmpty);
      expect(session.cursorModel.offset, const Offset(-800, 400));
      expect(session.cursorModel.x, 1120);
      expect(session.cursorModel.y, 400);
    },
  );
}
