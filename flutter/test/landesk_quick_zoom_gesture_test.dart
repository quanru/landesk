import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/quick_zoom_gesture.dart';

void main() {
  testWidgets('double tap drag zooms without double clicking or panning', (
    tester,
  ) async {
    var doubles = 0;
    var pans = 0;
    var taps = 0;
    var holds = 0;
    final zooms = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: RawGestureDetector(
          gestures: {
            QuickZoomGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  QuickZoomGestureRecognizer
                >(
                  () => QuickZoomGestureRecognizer(),
                  (r) => r
                    ..onDoubleTap = (_) {
                      doubles++;
                    }
                    ..onZoom = (dy, _) {
                      zooms.add(dy);
                    },
                ),
            TapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (r) => r
                    ..onTap = () {
                      taps++;
                    },
                ),
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(),
                  (r) => r
                    ..onLongPress = () {
                      holds++;
                    },
                ),
            DoubleTapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  DoubleTapGestureRecognizer
                >(
                  () => DoubleTapGestureRecognizer(),
                  (r) => r
                    ..onDoubleTap = () {
                      doubles++;
                    },
                ),
            PanGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(),
                  (r) => r
                    ..onUpdate = (_) {
                      pans++;
                    },
                ),
          },
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 80));
    final finger = await tester.createGesture();
    await finger.down(
      const Offset(200, 200),
      timeStamp: const Duration(milliseconds: 80),
    );
    await tester.pump(const Duration(milliseconds: 550));
    await finger.moveBy(const Offset(0, -40));
    await finger.moveBy(const Offset(0, 20));
    await finger.up();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(zooms, [-40, 20]);
    expect(doubles, 0);
    expect(pans, 0);
    expect(taps, 0);
    expect(holds, 0);
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 80));
    final second = await tester.createGesture();
    await second.down(
      const Offset(200, 200),
      timeStamp: const Duration(milliseconds: 80),
    );
    await second.up(timeStamp: const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(doubles, 1);
    // An isolated tap and drag still belong to the ordinary recognizers.
    await tester.tapAt(const Offset(400, 200));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(taps, 1);
    await tester.dragFrom(const Offset(400, 200), const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(pans, greaterThan(0));
    final zoomCount = zooms.length;
    // Cancelling the second contact must not leave zoom armed.
    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 80));
    final cancelled = await tester.createGesture();
    await cancelled.down(
      const Offset(200, 200),
      timeStamp: const Duration(milliseconds: 80),
    );
    await cancelled.cancel();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(400, 200), const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(zooms.length, zoomCount);
    expect(doubles, 1);
    expect(tester.takeException(), isNull);
  });
}
