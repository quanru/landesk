part of 'cursor_replay_test.dart';

final registered = <String>[];
final deleted = <String>[];
late _FFI ffi;

/// Stands in for the core, which keeps every shape the peer sent.
class _Cursor extends CursorModel {
  _Cursor(FFI ffi) : super(WeakReference(ffi));
  final core = <String, CursorShape>{};
  final fetched = <String>[];
  // While set, a fetch answers only when [answerFetches] is called.
  bool holdFetches = false;
  // While set, a fetch throws before it returns a future.
  bool throwAtOnce = false;
  final _held = <Completer<CursorShape?>, String>{};
  @override
  Future<CursorShape?> fetchCursorShape(String id) {
    fetched.add(id);
    if (throwAtOnce) throw StateError('no core');
    if (!holdFetches) return Future.value(core[id]);
    final answer = Completer<CursorShape?>();
    _held[answer] = id;
    return answer.future;
  }

  void answerFetches() {
    final held = Map.of(_held);
    _held.clear();
    held.forEach((answer, id) => answer.complete(core[id]));
  }

  void failFetches() {
    final held = Map.of(_held);
    _held.clear();
    held.forEach((answer, _) => answer.completeError(StateError('failed')));
  }

  bool showRemoteCursor = false;
  @override
  bool get showsRemoteCursor => showRemoteCursor;
}

String? _key(MouseCursor cursor) =>
    cursor is FlutterCustomMemoryImageCursor ? cursor.key : null;

class _FFI extends Fake implements FFI {
  _FFI() {
    ffiModel = FfiModel(WeakReference(this));
    cursorModel = _Cursor(this);
  }
  @override
  final SessionID sessionId = const Uuid().v4obj();
  @override
  late final FfiModel ffiModel;
  @override
  late final CursorModel cursorModel;
  _Cursor get cursor => cursorModel as _Cursor;
}

Uint8List _pixels(int size, int seed) =>
    Uint8List.fromList(List.generate(size * size * 4, (i) => (i + seed) % 256));

/// A shape as the core delivers it, and keeps it.
Future<void> _feed(_FFI ffi, String id, {int size = 8, int seed = 0}) {
  final pixels = _pixels(size, seed);
  ffi.cursor.core[id] = CursorShape(
    hotx: 0,
    hoty: 0,
    width: size,
    height: size,
    colors: pixels,
  );
  return ffi.ffiModel.handleCursorData(id, 0, 0, size, size, pixels);
}

void _select(_FFI ffi, String id) {
  final evt = {'id': id};
  ffi.ffiModel.updateLastCursorId(evt);
  ffi.ffiModel.handleCursorId(evt);
}

Future<void> _settle() async {
  for (var i = 0; i < 2; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void _captureCursorCalls(
  TestWidgetsFlutterBinding binding,
  MethodChannel channel,
  List<String> registered,
  List<String> deleted,
) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    call,
  ) async {
    final args = call.arguments as Map<dynamic, dynamic>;
    if (call.method.startsWith('createCustomCursor')) {
      registered.add(args['name'] as String);
      return args['name'];
    }
    if (call.method.startsWith('deleteCustomCursor')) {
      deleted.add(args['name'] as String);
    }
    return null;
  });
}
