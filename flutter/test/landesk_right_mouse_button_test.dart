import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/virtual_right_mouse_button.dart';

void main() {
  testWidgets('right click is labeled, pressed visibly and leaves background interactive', (tester) async {
    var clicks = 0;
    var canvas = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(behavior: HitTestBehavior.opaque,
          onTap: () => canvas++, child: const SizedBox.expand()),
        VirtualRightMouseButton(onTap: () async => clicks++, editing: false,
          onPosition: (_) {}, onPositionEnd: () {}),
      ],
    ))));
    expect(find.text('Right'), findsOneWidget);
    final button = find.bySemanticsLabel('Right mouse button');
    final before = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration;
    final touch = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration, isNot(before));
    await touch.up();
    await tester.pumpAndSettle();
    expect(clicks, 1);
    expect(canvas, 0);
    await tester.tapAt(const Offset(20, 20));
    expect(canvas, 1);
  });
}
