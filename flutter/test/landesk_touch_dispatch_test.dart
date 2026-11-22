import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/remote_input.dart';
import 'package:flutter_hbb/common.dart' show AccessibilityListener;
import 'package:flutter_hbb/common.dart' as common;
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

class _Input extends Fake implements InputModel {
  final events = <String>[];
  @override
  bool shouldIgnoreTouchTap(Offset position) => false;
  @override
  Future<void> tapDown(MouseButtons button) async => events.add('down');
  @override
  Future<void> tapUp(MouseButtons button) async => events.add('up');
  @override
  Future<void> tap(MouseButtons button) async => events.add('tap:$button');
}
class _Cursor extends Fake implements CursorModel {
  Offset? position;
  @override
  bool isInRemoteRect(Offset point) => true;
  @override
  Future<bool> move(double x, double y) async {
    position = Offset(x, y);
    return true;
  }
}
class _Model extends Fake implements FfiModel {
  @override
  bool get touchMode => true;
  @override
  bool get isPeerAndroid => false;
  @override
  bool get isPeerMobile => false;
}
class _FFI extends Fake implements FFI {
  @override
  final _Input inputModel = _Input();
  @override
  final _Cursor cursorModel = _Cursor();
  @override
  final _Model ffiModel = _Model();
}
void main() {
  testWidgets('keyboard toolbar does not block canvas below the safe area', (tester) async {
    final wasMobile = common.isMobile;
    common.isMobile = true;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(left: 12, top: 35);
    addTearDown(() {
      common.isMobile = wasMobile;
      tester.view.resetPadding();
      tester.view.resetDevicePixelRatio();
    });
    final ffi = _FFI();
    final cursor = CursorModel(WeakReference(ffi));
    cursor.keyHelpToolsVisibilityChanged(const Rect.fromLTWH(12, 35, 400, 200), false);
    expect(cursor.shouldBlock(100, 210), isFalse);
    expect(cursor.shouldBlock(100, 100), isTrue);
    cursor.dispose();
  });

  testWidgets('accessibility touch produces one remote click', (tester) async {
    final ffi = _FFI();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      AccessibilityListener(child: RawTouchGestureDetectorRegion(ffi: ffi,
        child: const ColoredBox(color: Colors.black, child: SizedBox.expand()))))));
    await tester.sendEventToBinding(const PointerDownEvent(
        pointer: 12, position: Offset(250, 180), size: 1));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.sendEventToBinding(const PointerUpEvent(
        pointer: 12, position: Offset(250, 180), size: 1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ffi.cursorModel.position, const Offset(250, 180));
    expect(ffi.inputModel.events, ['down', 'up']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real touch handlers move to the tapped point and click once', (tester) async {
    final ffi = _FFI();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      RawTouchGestureDetectorRegion(ffi: ffi,
        child: const ColoredBox(color: Colors.black, child: SizedBox.expand())))));
    await tester.tapAt(const Offset(250, 180));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ffi.cursorModel.position, const Offset(250, 180));
    expect(ffi.inputModel.events, ['down', 'up']);
    expect(tester.takeException(), isNull);
  });
}
