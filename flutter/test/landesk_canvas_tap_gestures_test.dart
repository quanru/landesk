import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/widgets/gestures.dart';

void main() {
  testWidgets(
    'canvas single tap is left, simultaneous two-finger tap is right, pinch is neither',
    (tester) async {
      final clicks = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RawGestureDetector(
            gestures: {
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (g) => g.onTap = () => clicks.add('left'),
                  ),
              DoubleFinerTapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    DoubleFinerTapGestureRecognizer
                  >(
                    () => DoubleFinerTapGestureRecognizer(),
                    (g) => g.onDoubleFinerTap = (_) => clicks.add('right'),
                  ),
              CustomTouchGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    CustomTouchGestureRecognizer
                  >(() => CustomTouchGestureRecognizer(), (_) {}),
            },
            child: const ColoredBox(
              color: Colors.white,
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(clicks, ['left']);
      clicks.clear();
      final a = await tester.startGesture(const Offset(200, 200), pointer: 1);
      final b = await tester.startGesture(const Offset(240, 200), pointer: 2);
      await a.up();
      await b.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(clicks, ['right']);
      clicks.clear();
      final c = await tester.startGesture(const Offset(200, 200), pointer: 1);
      final d = await tester.startGesture(const Offset(240, 200), pointer: 2);
      await c.moveBy(const Offset(-80, 0));
      await d.moveBy(const Offset(80, 0));
      await c.up();
      await d.up();
      await tester.pump(const Duration(milliseconds: 400));
      expect(clicks, isEmpty);
    },
  );
}
