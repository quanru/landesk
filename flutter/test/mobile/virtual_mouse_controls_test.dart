import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/virtual_mouse_controls.dart';

void main() {
  testWidgets('left drag, right click and cancellation preserve event order', (
    tester,
  ) async {
    final events = <String>[];
    int background = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            GestureDetector(
              onTap: () => background++,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
            VirtualMouseControls(
              button: (b, d) async => events.add('$b:$d'),
              scroll: (_) async {},
              move: (_) async => events.add('move'),
              translate: (s) => s,
              onPosition: (_, __) {},
              onPositionEnd: () {},
            ),
          ],
        ),
      ),
    );
    final left = find.byKey(const ValueKey('virtual-mouse-left'));
    final drag = await tester.startGesture(tester.getCenter(left));
    await tester.pump();
    await drag.moveBy(const Offset(20, 5));
    await tester.pump();
    await drag.cancel();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('virtual-mouse-right')));
    await tester.pump();
    expect(events, [
      'left:true',
      'move',
      'left:false',
      'right:true',
      'right:false',
    ]);
    expect(background, 0);
    await tester.tapAt(const Offset(400, 200));
    expect(background, 1);
  });

  testWidgets('wheel tap, delayed repeat, release and slide direction', (
    tester,
  ) async {
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: VirtualMouseControls(
          button: (_, __) async {},
          scroll: (n) async => steps.add(n),
          move: (_) async {},
          translate: (s) => s,
          onPosition: (_, __) {},
          onPositionEnd: () {},
        ),
      ),
    );
    final up = find.byKey(const ValueKey('virtual-wheel-up'));
    final hold = await tester.startGesture(tester.getCenter(up));
    await tester.pump(const Duration(milliseconds: 300));
    expect(steps, [1]);
    await tester.pump(const Duration(milliseconds: 60));
    expect(steps, [1, 1]);
    await hold.up();
    await tester.pump(const Duration(seconds: 1));
    expect(steps, [1, 1]);
    final slide = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('virtual-wheel-slide'))),
    );
    await slide.moveBy(const Offset(0, 25));
    await tester.pump();
    await slide.up();
    expect(steps.last, -2);
  });

  testWidgets('slow wheel is bounded and removal releases a held mouse', (
    tester,
  ) async {
    final pending = Completer<void>();
    final events = <String>[];
    int calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: VirtualMouseControls(
          button: (b, d) async => events.add('$b:$d'),
          scroll: (_) {
            calls++;
            return pending.future;
          },
          move: (_) async {},
          translate: (s) => s,
          onPosition: (_, __) {},
          onPositionEnd: () {},
        ),
      ),
    );
    final hold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('virtual-wheel-up'))),
      pointer: 1,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 1);
    final mouse = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('virtual-mouse-left'))),
      pointer: 2,
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    pending.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(events, ['left:true', 'left:false']);
    await hold.cancel();
    await mouse.cancel();
  });

  testWidgets('background releases buttons and stops wheel repeat', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: VirtualMouseControls(
          button: (b, d) async => events.add('$b:$d'),
          scroll: (_) async => events.add('wheel'),
          move: (_) async {},
          translate: (s) => s,
          onPosition: (_, __) {},
          onPositionEnd: () {},
        ),
      ),
    );
    final mouse = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('virtual-mouse-left'))),
      pointer: 1,
    );
    final wheel = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('virtual-wheel-up'))),
      pointer: 2,
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 1));
    expect(events, ['left:true', 'wheel', 'left:false']);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await mouse.cancel();
    await wheel.cancel();
  });
}
