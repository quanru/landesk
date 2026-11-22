import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/overlay.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends Fake implements FFI {}

class _VisibleMonitor extends QualityMonitorModel {
  _VisibleMonitor(FFI session) : super(WeakReference(session));

  @override
  bool get show => true;
}

void main() {
  testWidgets('quality monitor stays inside a narrow window with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(240, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = _Session();
    final model = _VisibleMonitor(session);
    addTearDown(model.dispose);
    model.data
      ..speed = '12.5 MB/s'
      ..codecFormat = 'H.264';

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(240, 720),
            textScaler: TextScaler.linear(2.5),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned(top: 10, right: 10, child: QualityMonitor(model)),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('12.5 MB/s'), findsOneWidget);
    expect(find.text('H.264'), findsOneWidget);
    final bounds = tester.getRect(find.byType(QualityMonitor));
    expect(bounds.left, greaterThanOrEqualTo(10));
    expect(bounds.right, lessThanOrEqualTo(230));
    expect(tester.takeException(), isNull);
  });
}
